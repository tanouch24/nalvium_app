import 'dart:convert';

/// Profil de la maison, renseigné au démarrage (chaque réponse est facultative).
/// Il reste UNIQUEMENT sur le téléphone : il n'est jamais envoyé au serveur.
class HomeProfile {
  const HomeProfile({
    this.housing,
    this.tenure,
    this.heating,
    this.hotWater,
    this.diyLevel,
    this.vitals = const {},
    this.maintenanceDone = const {},
  });

  /// apartment | house
  final String? housing;

  /// tenant | owner
  final String? tenure;

  /// gas | electric | heat_pump | oil_wood | unknown
  final String? heating;

  /// boiler | electric_tank | unknown
  final String? hotWater;

  /// beginner | handy | confident
  final String? diyLevel;

  /// Points vitaux (vanne d'eau, tableau électrique, compteur gaz) : photo locale et/ou « absent ».
  final Map<VitalPoint, VitalInfo> vitals;

  /// Dernière date à laquelle chaque entretien a été marqué « fait » (clé = MaintenanceTask.id).
  final Map<String, DateTime> maintenanceDone;

  HomeProfile copyWith({
    String? housing,
    String? tenure,
    String? heating,
    String? hotWater,
    String? diyLevel,
    Map<VitalPoint, VitalInfo>? vitals,
    Map<String, DateTime>? maintenanceDone,
  }) => HomeProfile(
    housing: housing ?? this.housing,
    tenure: tenure ?? this.tenure,
    heating: heating ?? this.heating,
    hotWater: hotWater ?? this.hotWater,
    diyLevel: diyLevel ?? this.diyLevel,
    vitals: vitals ?? this.vitals,
    maintenanceDone: maintenanceDone ?? this.maintenanceDone,
  );

  /// Nombre de réponses de profil données (sur 5).
  int get answered => [housing, tenure, heating, hotWater, diyLevel].where((v) => v != null).length;

  Map<String, dynamic> toJson() => {
    'housing': housing,
    'tenure': tenure,
    'heating': heating,
    'hot_water': hotWater,
    'diy_level': diyLevel,
    'vitals': {for (final e in vitals.entries) e.key.name: e.value.toJson()},
    'maintenance_done': {for (final e in maintenanceDone.entries) e.key: e.value.toIso8601String()},
  };

  static HomeProfile fromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return const HomeProfile();
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return HomeProfile(
        housing: j['housing'] as String?,
        tenure: j['tenure'] as String?,
        heating: j['heating'] as String?,
        hotWater: j['hot_water'] as String?,
        diyLevel: j['diy_level'] as String?,
        vitals: {
          for (final e in (j['vitals'] as Map<String, dynamic>? ?? const {}).entries)
            if (VitalPoint.values.any((v) => v.name == e.key))
              VitalPoint.values.byName(e.key): VitalInfo.fromJson(e.value as Map<String, dynamic>),
        },
        maintenanceDone: {
          for (final e in (j['maintenance_done'] as Map<String, dynamic>? ?? const {}).entries)
            if (DateTime.tryParse(e.value as String? ?? '') != null) e.key: DateTime.parse(e.value as String),
        },
      );
    } catch (_) {
      return const HomeProfile(); // un profil illisible ne doit jamais bloquer l'app
    }
  }

  String toJsonString() => jsonEncode(toJson());
}

enum VitalPoint { waterValve, electricalPanel, gasMeter }

class VitalInfo {
  const VitalInfo({this.photoPath, this.absent = false});

  /// Photo locale (dossier privé de l'app).
  final String? photoPath;

  /// L'utilisateur indique ne pas en avoir (ex. pas de gaz).
  final bool absent;

  bool get known => photoPath != null || absent;

  Map<String, dynamic> toJson() => {'photo_path': photoPath, 'absent': absent};

  factory VitalInfo.fromJson(Map<String, dynamic> j) =>
      VitalInfo(photoPath: j['photo_path'] as String?, absent: j['absent'] as bool? ?? false);
}

/// Entretien régulier recommandé, déduit du profil. Ce sont des rappels, pas des obligations vérifiées.
class MaintenanceTask {
  const MaintenanceTask({required this.id, required this.intervalDays, this.mandatory = false});
  final String id;
  final int intervalDays;

  /// Entretien annuel obligatoire en France (chaudière gaz/fioul/bois).
  final bool mandatory;

  static const boiler = MaintenanceTask(id: 'boiler', intervalDays: 365, mandatory: true);
  static const radiators = MaintenanceTask(id: 'radiators', intervalDays: 365);
  static const heatPump = MaintenanceTask(id: 'heat_pump', intervalDays: 365);
  static const waterHeater = MaintenanceTask(id: 'water_heater', intervalDays: 180);
  static const vmc = MaintenanceTask(id: 'vmc', intervalDays: 180);
  static const smokeAlarm = MaintenanceTask(id: 'smoke_alarm', intervalDays: 90);

  /// Liste adaptée au profil (toujours au moins la VMC et le détecteur de fumée).
  static List<MaintenanceTask> forProfile(HomeProfile p) => [
    if (p.heating == 'gas' || p.heating == 'oil_wood' || p.hotWater == 'boiler') boiler,
    if (p.heating == 'heat_pump') heatPump,
    if (p.heating == 'gas' || p.heating == 'oil_wood' || p.heating == 'heat_pump') radiators,
    if (p.hotWater == 'electric_tank') waterHeater,
    vmc,
    smokeAlarm,
  ];

  /// Prochaine échéance ; null = jamais marqué fait (« à planifier »).
  DateTime? dueDate(HomeProfile p) {
    final done = p.maintenanceDone[id];
    return done?.add(Duration(days: intervalDays));
  }

  bool isUpToDate(HomeProfile p, DateTime now) {
    final due = dueDate(p);
    return due != null && due.isAfter(now);
  }
}

/// Suivi de la maison (0–100) : ce que l'utilisateur a documenté et entretenu. Ce n'est PAS une inspection :
/// le libellé affiché le dit (« Suivi de votre maison »).
int homeFollowUpScore(HomeProfile p, DateTime now) {
  final tasks = MaintenanceTask.forProfile(p);
  final profile = p.answered / 5 * 30;
  final vitals = VitalPoint.values.where((v) => p.vitals[v]?.known ?? false).length / VitalPoint.values.length * 30;
  final upToDate = tasks.isEmpty ? 0 : tasks.where((t) => t.isUpToDate(p, now)).length / tasks.length * 40;
  return (profile + vitals + upToDate).round().clamp(0, 100);
}
