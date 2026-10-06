import 'text.dart';

/// Version du consentement affiché à l'utilisateur (doit correspondre au backend).
const kConsentVersion = '2026-10';

/// Zone où les interventions humaines sont disponibles (info d'affichage venant du SERVEUR).
class ServiceAreaInfo {
  const ServiceAreaInfo({required this.name, required this.radiusKm});
  final String name;
  final int radiusKm;
  factory ServiceAreaInfo.fromJson(Map<String, dynamic> j) => ServiceAreaInfo(name: j['name'] as String, radiusKm: j['radius_km'] as int);
}

/// Résultat d'éligibilité (informatif : le contrôle définitif est fait par le serveur à l'envoi).
class AreaCheck {
  const AreaCheck({required this.status, this.code});
  final String status; // in_zone | out_of_zone | invalid
  final String? code; // invalid_postal_code | unknown_postal_code | unknown_city | city_postal_mismatch
  bool get inZone => status == 'in_zone';
  bool get outOfZone => status == 'out_of_zone';
  factory AreaCheck.fromJson(Map<String, dynamic> j) => AreaCheck(status: j['status'] as String, code: j['code'] as String?);
}

enum RequestStatus {
  draft,
  submitted,
  contactPending,
  contacted,
  closed,
  cancelled;

  static RequestStatus fromWire(String v) => switch (v) {
    'SUBMITTED' => submitted,
    'CONTACT_PENDING' => contactPending,
    'CONTACTED' => contacted,
    'CLOSED' => closed,
    'CANCELLED' => cancelled,
    _ => draft,
  };

  bool get cancellable => this == draft || this == submitted || this == contactPending;
}

/// Disponibilité : une PRÉFÉRENCE, jamais une réservation.
enum AvailabilityType {
  asap('asap'),
  today('today'),
  tomorrow('tomorrow'),
  thisWeek('this_week'),
  custom('custom');

  const AvailabilityType(this.wire);
  final String wire;
  static AvailabilityType? fromWire(String? v) {
    for (final t in values) {
      if (t.wire == v) return t;
    }
    return null;
  }
}

const kTimeWindows = ['morning', 'afternoon', 'evening'];

class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.status,
    required this.createdAt,
    this.sessionId,
    this.equipmentId,
    this.category,
    this.summary,
    this.firstName,
    this.phone,
    this.email,
    this.city,
    this.postalCode,
    this.availability,
    this.preferredDate,
    this.timeWindow,
    this.mediaIds = const [],
    this.context = const {},
    this.submittedAt,
    this.equipmentLabel,
  });

  final String id;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? submittedAt;
  final String? sessionId;
  final String? equipmentId;
  final String? category;
  final String? summary;
  final String? firstName;
  final String? phone;
  final String? email;
  final String? city;
  final String? postalCode;
  final AvailabilityType? availability;
  final String? preferredDate;
  final String? timeWindow;
  final List<String> mediaIds;
  final Map<String, dynamic> context;
  final String? equipmentLabel;

  Map<String, dynamic>? get equipment => context['equipment'] as Map<String, dynamic>?;
  List<String> get observations => _strings(context['observations']);
  List<Map<String, dynamic>> get actionsTried => _maps(context['actions_tried']);
  List<Map<String, dynamic>> get hypotheses => _maps(context['hypotheses']);
  String? get safetyReason => context['safety_stop_reason'] as String?;
  String? get professionalReason => context['professional_reason'] as String?;
  Map<String, dynamic>? get manual => context['manual'] as Map<String, dynamic>?;

  factory ServiceRequest.fromJson(Map<String, dynamic> j) => ServiceRequest(
    id: j['id'] as String,
    status: RequestStatus.fromWire(j['status'] as String),
    createdAt: DateTime.parse(j['created_at'] as String),
    submittedAt: j['submitted_at'] == null ? null : DateTime.parse(j['submitted_at'] as String),
    sessionId: j['diagnostic_session_id'] as String?,
    equipmentId: j['equipment_id'] as String?,
    category: j['problem_category'] as String?,
    summary: j['problem_summary'] == null ? null : cleanText(j['problem_summary'] as String),
    firstName: j['first_name'] as String?,
    phone: j['phone'] as String?,
    email: j['email'] as String?,
    city: j['city'] as String?,
    postalCode: j['postal_code'] as String?,
    availability: AvailabilityType.fromWire(j['availability_type'] as String?),
    preferredDate: j['preferred_date'] as String?,
    timeWindow: j['preferred_time_window'] as String?,
    mediaIds: [for (final m in j['media_ids'] as List? ?? const []) m as String],
    context: (j['context'] as Map<String, dynamic>?) ?? const {},
    equipmentLabel: j['equipment_label'] as String?,
  );
}

List<String> _strings(Object? v) => [for (final e in v as List? ?? const []) cleanText(e as String)];
List<Map<String, dynamic>> _maps(Object? v) => [for (final e in v as List? ?? const []) e as Map<String, dynamic>];

/// Validation locale (le serveur valide aussi). Retourne un code d'erreur stable ou null.
abstract final class RequestValidation {
  static String? phone(String raw) {
    final d = raw.replaceAll(RegExp(r'[\s.\-()]'), '');
    final n = d.startsWith('0033') ? '+33${d.substring(4)}' : d;
    if (RegExp(r'^0[1-9]\d{8}$').hasMatch(n)) return null;
    if (RegExp(r'^\+33[1-9]\d{8}$').hasMatch(n)) return null;
    if (RegExp(r'^\+(?!33)[1-9]\d{7,14}$').hasMatch(n)) return null;
    return 'invalid_phone';
  }

  static String? postalCode(String raw) {
    final c = raw.trim();
    if (!RegExp(r'^\d{5}$').hasMatch(c)) return 'invalid_postal_code';
    final dep = c.substring(0, 2);
    return (dep.compareTo('01') >= 0 && dep.compareTo('95') <= 0) || dep == '97' || dep == '98' ? null : 'invalid_postal_code';
  }

  static String? email(String raw) {
    final e = raw.trim();
    if (e.isEmpty) return null;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$').hasMatch(e) ? null : 'invalid_email';
  }
}
