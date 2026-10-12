import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/home_profile.dart';

/// Version de l'information IA à laquelle l'utilisateur a donné son accord. Si le texte change de façon
/// importante, augmenter la version : l'accord est redemandé.
const kAiConsentVersion = '2026-10';

/// Préférences locales (téléphone uniquement) : démarrage terminé, accord IA, profil de la maison.
class LocalStore {
  LocalStore(this._prefs);
  final SharedPreferences _prefs;

  static const _onboarded = 'nalvium.onboarded';
  static const _aiConsent = 'nalvium.ai_consent';
  static const _profile = 'nalvium.home_profile';

  bool get onboarded => _prefs.getBool(_onboarded) ?? false;
  Future<void> setOnboarded() => _prefs.setBool(_onboarded, true);

  bool get hasAiConsent => _prefs.getString(_aiConsent) == kAiConsentVersion;
  Future<void> giveAiConsent() => _prefs.setString(_aiConsent, kAiConsentVersion);
  Future<void> withdrawAiConsent() => _prefs.remove(_aiConsent);

  HomeProfile get profile => HomeProfile.fromJsonString(_prefs.getString(_profile));
  Future<void> saveProfile(HomeProfile p) => _prefs.setString(_profile, p.toJsonString());

  static const _savingsSeen = 'nalvium.savings_seen';
  static const _tipPromptAt = 'nalvium.tip_prompt_at';

  /// Dernier total d'économies vu sur l'accueil (le compteur s'anime seulement s'il a augmenté depuis).
  int? get savingsSeen => _prefs.getInt(_savingsSeen);
  Future<void> setSavingsSeen(int total) => _prefs.setInt(_savingsSeen, total);

  /// Dernière proposition de pourboire après une réparation (au plus une tous les 14 jours).
  DateTime? get tipPromptAt {
    final ms = _prefs.getInt(_tipPromptAt);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setTipPromptAt(DateTime when) => _prefs.setInt(_tipPromptAt, when.millisecondsSinceEpoch);

  static const _profilePending = 'nalvium.profile_pending';
  static const _reminders = 'nalvium.maintenance_reminders';
  static const _remindersSince = 'nalvium.maintenance_reminders_since';
  static const _afterPhotos = 'nalvium.after_photos';

  /// Premier diagnostic lancé avant le profil (« moment wow ») : le carnet maison reste à compléter.
  bool get profileSetupPending => _prefs.getBool(_profilePending) ?? false;
  Future<void> setProfileSetupPending(bool pending) =>
      pending ? _prefs.setBool(_profilePending, true) : _prefs.remove(_profilePending);

  /// Rappels d'entretien (notifications programmées sur le téléphone, rien n'est envoyé).
  bool get maintenanceReminders => _prefs.getBool(_reminders) ?? false;

  /// Date d'activation des rappels : repère des entretiens jamais notés (« à planifier »).
  DateTime? get maintenanceRemindersSince {
    final ms = _prefs.getInt(_remindersSince);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setMaintenanceReminders(bool on, {DateTime? since}) async {
    await _prefs.setBool(_reminders, on);
    if (on && since != null) {
      await _prefs.setInt(_remindersSince, since.millisecondsSinceEpoch);
    } else if (!on) {
      await _prefs.remove(_remindersSince);
    }
  }

  /// Photos « après » (chemin local dans le dossier privé de l'app), par session. Jamais envoyées.
  Map<String, String> get afterPhotos {
    final raw = _prefs.getString(_afterPhotos);
    if (raw == null || raw.isEmpty) return const {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return const {}; // illisible : jamais bloquant
    }
  }

  Future<void> saveAfterPhotos(Map<String, String> photos) => _prefs.setString(_afterPhotos, jsonEncode(photos));

  /// Après « Supprimer mes données » : le profil local, l'accord IA et les photos « après » sont effacés aussi.
  Future<void> clearPersonal() async {
    await _prefs.remove(_profile);
    await _prefs.remove(_aiConsent);
    await _prefs.remove(_savingsSeen);
    await _prefs.remove(_afterPhotos);
    await _prefs.remove(_profilePending);
  }
}
