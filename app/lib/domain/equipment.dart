import 'package:flutter/material.dart';

import 'text.dart';

/// Type d'équipement : liste COURTE et extensible. Un slug inconnu s'affiche comme « Autre ».
class EquipmentKind {
  const EquipmentKind(this.slug, this.label, this.icon, {this.feminine = false});
  final String slug;
  final String label;
  final IconData icon;
  final bool feminine;

  /// « un lave-vaisselle », « une chaudière » (pour parler d'une identification incertaine).
  String get withArticle => '${feminine ? 'une' : 'un'} ${label.toLowerCase()}';
}

abstract final class EquipmentCatalog {
  static const other = EquipmentKind('other', 'Autre', Icons.home_repair_service_outlined);

  static const kinds = <EquipmentKind>[
    EquipmentKind('dishwasher', 'Lave-vaisselle', Icons.restaurant_outlined),
    EquipmentKind('washing_machine', 'Lave-linge', Icons.local_laundry_service_outlined),
    EquipmentKind('fridge', 'Réfrigérateur', Icons.kitchen_outlined),
    EquipmentKind('oven', 'Four', Icons.microwave_outlined),
    EquipmentKind('hob', 'Plaque', Icons.local_fire_department_outlined, feminine: true),
    EquipmentKind('boiler', 'Chaudière', Icons.whatshot_outlined, feminine: true),
    EquipmentKind('water_heater', 'Chauffe-eau', Icons.device_thermostat_outlined),
    EquipmentKind('radiator', 'Radiateur', Icons.thermostat_outlined),
    EquipmentKind('air_conditioner', 'Climatisation', Icons.ac_unit_rounded, feminine: true),
    EquipmentKind('sink', 'Évier', Icons.countertops_outlined),
    EquipmentKind('washbasin', 'Lavabo', Icons.water_drop_outlined),
    EquipmentKind('shower', 'Douche', Icons.shower_outlined, feminine: true),
    EquipmentKind('toilet', 'WC', Icons.wc_rounded),
    EquipmentKind('tap', 'Robinet', Icons.plumbing_outlined),
    EquipmentKind('vmc', 'VMC', Icons.air_rounded, feminine: true),
    EquipmentKind('electrical_panel', 'Tableau électrique', Icons.electrical_services_outlined),
    EquipmentKind('socket', 'Prise', Icons.power_outlined, feminine: true),
    EquipmentKind('light', 'Luminaire', Icons.lightbulb_outline_rounded),
    EquipmentKind('door', 'Porte', Icons.sensor_door_outlined, feminine: true),
    EquipmentKind('window', 'Fenêtre', Icons.window_outlined, feminine: true),
    EquipmentKind('shutter', 'Volet', Icons.blinds_outlined),
    other,
  ];

  static EquipmentKind of(String slug) =>
      kinds.firstWhere((k) => k.slug == slug, orElse: () => other);

  /// Minuscules sans accents, pour la recherche.
  static String fold(String s) {
    const from = 'àâäéèêëîïôöùûüçœ';
    const to = 'aaaeeeeiiooouuuco';
    final buf = StringBuffer();
    for (final c in s.toLowerCase().split('')) {
      final i = from.indexOf(c);
      buf.write(i >= 0 ? to[i] : c);
    }
    return buf.toString();
  }

  static List<EquipmentKind> search(String query) {
    final q = fold(query.trim());
    if (q.isEmpty) return kinds;
    return [for (final k in kinds) if (fold(k.label).contains(q)) k];
  }
}

/// Pièce : par son NOM (« Cuisine »), jamais une localisation.
class RoomKind {
  const RoomKind(this.slug, this.label, this.icon);
  final String slug;
  final String label;
  final IconData icon;
}

abstract final class RoomCatalog {
  static const kinds = <RoomKind>[
    RoomKind('kitchen', 'Cuisine', Icons.soup_kitchen_outlined),
    RoomKind('bathroom', 'Salle de bain', Icons.bathtub_outlined),
    RoomKind('living', 'Salon', Icons.weekend_outlined),
    RoomKind('bedroom', 'Chambre', Icons.bed_outlined),
    RoomKind('laundry', 'Buanderie', Icons.local_laundry_service_outlined),
    RoomKind('garage', 'Garage', Icons.garage_outlined),
    RoomKind('outdoor', 'Extérieur', Icons.yard_outlined),
    RoomKind('other', 'Autre', Icons.meeting_room_outlined),
  ];

  static RoomKind? of(String? slug) {
    for (final k in kinds) {
      if (k.slug == slug) return k;
    }
    return null;
  }
}

class EquipmentSummary {
  const EquipmentSummary({
    required this.id,
    required this.equipmentType,
    required this.displayName,
    this.brand,
    this.model,
    this.roomType,
    this.roomName,
    this.photoMediaId,
    this.diagnosticsCount = 0,
  });

  final String id;
  final String equipmentType;
  final String displayName;
  final String? brand;
  final String? model;
  final String? roomType;
  final String? roomName;
  final String? photoMediaId;
  final int diagnosticsCount;

  EquipmentKind get kind => EquipmentCatalog.of(equipmentType);

  factory EquipmentSummary.fromJson(Map<String, dynamic> j) => EquipmentSummary(
    id: j['id'] as String,
    equipmentType: j['equipment_type'] as String,
    displayName: cleanText(j['display_name'] as String),
    brand: _opt(j['brand']),
    model: _opt(j['model']),
    roomType: j['room_type'] as String?,
    roomName: j['room_name'] as String?,
    photoMediaId: j['photo_media_id'] as String?,
    diagnosticsCount: j['diagnostics_count'] as int? ?? 0,
  );
}

String? _opt(Object? v) => v == null ? null : cleanText(v as String);

/// Diagnostic réellement lié à un équipement (fiche équipement).
class EquipmentDiagnostic {
  const EquipmentDiagnostic({
    required this.id,
    required this.status,
    required this.updatedAt,
    this.title,
  });
  final String id;
  final String status;
  final String? title;
  final DateTime updatedAt;

  factory EquipmentDiagnostic.fromJson(Map<String, dynamic> j) => EquipmentDiagnostic(
    id: j['id'] as String,
    status: j['status'] as String,
    title: _opt(j['title']),
    updatedAt: DateTime.parse(j['updated_at'] as String),
  );
}

/// Notice constructeur liée à un équipement (privée, côté serveur).
class ManualInfo {
  const ManualInfo({
    required this.status,
    this.errorCode,
    this.title,
    this.manufacturer,
    this.modelReference,
    this.sourceDomain,
    this.official = false,
    this.pageCount,
    this.matchLevel,
  });

  /// available | needs_confirmation | not_found | error
  final String status;
  final String? errorCode;
  final String? title;
  final String? manufacturer;
  final String? modelReference;
  final String? sourceDomain;
  final bool official;
  final int? pageCount;
  final String? matchLevel;

  bool get isAvailable => status == 'available';

  factory ManualInfo.fromJson(Map<String, dynamic> j) => ManualInfo(
    status: j['status'] as String,
    errorCode: j['error_code'] as String?,
    title: _opt(j['title']),
    manufacturer: _opt(j['manufacturer']),
    modelReference: _opt(j['model_reference']),
    sourceDomain: j['source_domain'] as String?,
    official: j['source_is_official'] as bool? ?? false,
    pageCount: j['page_count'] as int?,
    matchLevel: j['match_level'] as String?,
  );
}

/// Résultat d'une recherche de notice : found | needs_confirmation | up_to_date | kept | not_found | error.
class ManualSearchResult {
  const ManualSearchResult({required this.outcome, required this.manual});
  final String outcome;
  final ManualInfo manual;

  factory ManualSearchResult.fromJson(Map<String, dynamic> j) => ManualSearchResult(
    outcome: j['outcome'] as String,
    manual: ManualInfo.fromJson(j['manual'] as Map<String, dynamic>),
  );
}

class ManualPage {
  const ManualPage({required this.page, required this.pageCount, required this.text});
  final int page;
  final int pageCount;
  final String text;

  factory ManualPage.fromJson(Map<String, dynamic> j) => ManualPage(
    page: j['page'] as int,
    pageCount: j['page_count'] as int,
    text: j['text'] as String,
  );
}

class EquipmentDetail {
  const EquipmentDetail({required this.summary, required this.diagnostics, this.manual});
  final EquipmentSummary summary;
  final List<EquipmentDiagnostic> diagnostics;
  final ManualInfo? manual;

  factory EquipmentDetail.fromJson(Map<String, dynamic> j) => EquipmentDetail(
    manual: j['manual'] == null ? null : ManualInfo.fromJson(j['manual'] as Map<String, dynamic>),
    summary: EquipmentSummary.fromJson(j),
    diagnostics: [
      for (final d in j['diagnostics'] as List? ?? const [])
        EquipmentDiagnostic.fromJson(d as Map<String, dynamic>),
    ],
  );
}

class HomeData {
  const HomeData({required this.equipment});
  final List<EquipmentSummary> equipment;

  factory HomeData.fromJson(Map<String, dynamic> j) => HomeData(
    equipment: [
      for (final e in j['equipment'] as List? ?? const [])
        EquipmentSummary.fromJson(e as Map<String, dynamic>),
    ],
  );

  /// Pièces dans l'ordre d'apparition ; les équipements sans pièce sont regroupés à la fin.
  List<MapEntry<String?, List<EquipmentSummary>>> byRoom() {
    final groups = <String?, List<EquipmentSummary>>{};
    for (final e in equipment) {
      groups.putIfAbsent(e.roomName, () => []).add(e);
    }
    final named = groups.keys.nonNulls.toList();
    return [
      for (final k in named) MapEntry(k, groups[k]!),
      if (groups.containsKey(null)) MapEntry(null, groups[null]!),
    ];
  }
}

/// Proposition d'identification sur photo. Jamais une certitude : l'utilisateur confirme.
class EquipmentIdentification {
  const EquipmentIdentification({
    required this.equipmentType,
    required this.confidence,
    this.brand,
    this.model,
    this.visibleText = const [],
  });
  final String equipmentType; // slug ou « unknown »
  final String? brand;
  final String? model;
  final double confidence;
  final List<String> visibleText;

  bool get isUnknown => equipmentType == 'unknown';

  factory EquipmentIdentification.fromJson(Map<String, dynamic> j) => EquipmentIdentification(
    equipmentType: j['equipment_type'] as String,
    brand: _opt(j['brand']),
    model: _opt(j['model']),
    confidence: (j['confidence'] as num).toDouble(),
    visibleText: [for (final t in j['visible_text'] as List? ?? const []) cleanText(t as String)],
  );
}

/// Équipement lié à une session (récapitulatif, en-tête du diagnostic).
class EquipmentRef {
  const EquipmentRef({
    required this.id,
    required this.equipmentType,
    required this.displayName,
    this.brand,
    this.roomName,
  });
  final String id;
  final String equipmentType;
  final String displayName;
  final String? brand;
  final String? roomName;

  factory EquipmentRef.fromJson(Map<String, dynamic> j) => EquipmentRef(
    id: j['id'] as String,
    equipmentType: j['equipment_type'] as String,
    displayName: cleanText(j['display_name'] as String),
    brand: _opt(j['brand']),
    roomName: j['room_name'] as String?,
  );
}

/// Propositions de rattachement (rien n'est lié sans confirmation).
class EquipmentSuggestions {
  const EquipmentSuggestions({this.detectedType, this.matches = const []});
  final String? detectedType;
  final List<EquipmentSummary> matches;

  factory EquipmentSuggestions.fromJson(Map<String, dynamic> j) => EquipmentSuggestions(
    detectedType: j['detected_type'] as String?,
    matches: [
      for (final m in j['matches'] as List? ?? const [])
        EquipmentSummary.fromJson(m as Map<String, dynamic>),
    ],
  );
}

/// Champs saisis pour créer un équipement. Tout est facultatif sauf le type.
class EquipmentDraft {
  const EquipmentDraft({
    required this.equipmentType,
    this.displayName,
    this.roomType,
    this.brand,
    this.model,
    this.photoMediaId,
  });
  final String equipmentType;
  final String? displayName;
  final String? roomType;
  final String? brand;
  final String? model;
  final String? photoMediaId;

  Map<String, dynamic> toJson() => {
    'equipment_type': equipmentType,
    'display_name': ?_blank(displayName),
    'room_type': ?roomType,
    'brand': ?_blank(brand),
    'model': ?_blank(model),
    'primary_media_id': ?photoMediaId,
  };
}

String? _blank(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
