import 'dart:io';

/// Identifiants AdMob. DÉVELOPPEMENT : uniquement les IDs de TEST publiés par Google.
/// Les vrais identifiants ne doivent JAMAIS être commités : ils seront injectés plus tard
/// (dart-define) quand le compte AdMob existera. Voir aussi l'ID d'application dans
/// AndroidManifest.xml / Info.plist (ID de test pour l'instant).
class AdIds {
  const AdIds({required this.banner, required this.interstitial, required this.appOpen});

  final String banner;
  final String interstitial;
  final String appOpen;

  /// IDs de test Google (https://developers.google.com/admob/android/test-ads).
  static AdIds test() => Platform.isIOS
      ? const AdIds(
          banner: 'ca-app-pub-3940256099942544/2934735716',
          interstitial: 'ca-app-pub-3940256099942544/4411468910',
          appOpen: 'ca-app-pub-3940256099942544/5575463023',
        )
      : const AdIds(
          banner: 'ca-app-pub-3940256099942544/6300978111',
          interstitial: 'ca-app-pub-3940256099942544/1033173712',
          appOpen: 'ca-app-pub-3940256099942544/9257395921',
        );
}
