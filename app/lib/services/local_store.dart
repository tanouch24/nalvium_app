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

  /// Après « Supprimer mes données » : le profil local et l'accord IA sont effacés aussi.
  Future<void> clearPersonal() async {
    await _prefs.remove(_profile);
    await _prefs.remove(_aiConsent);
  }
}
