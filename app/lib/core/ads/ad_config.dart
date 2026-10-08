import 'dart:io';

import 'package:flutter/foundation.dart';

/// Identifiants AdMob.
///  • DEBUG / PROFILE / TESTS → IDs de TEST officiels de Google (jamais les IDs de production).
///  • RELEASE (Android / iOS) → blocs de production Nalvium. L'ID d'application suit la même règle : par type
///    de build dans `android/app/build.gradle.kts` (manifestPlaceholders) et `ios/Flutter/{Debug,Release}.xcconfig`.
class AdIds {
  const AdIds({required this.banner, required this.interstitial, required this.appOpen});

  final String banner;
  final String interstitial;
  final String appOpen;

  /// Blocs de production Nalvium (Android).
  static const productionAndroid = AdIds(
    banner: 'ca-app-pub-9787163762873138/7749641197',
    interstitial: 'ca-app-pub-9787163762873138/8092246961',
    appOpen: 'ca-app-pub-9787163762873138/1479657021',
  );

  /// Blocs de production Nalvium (iOS).
  static const productionIos = AdIds(
    banner: 'ca-app-pub-9787163762873138/8547612343',
    interstitial: 'ca-app-pub-9787163762873138/7234530675',
    appOpen: 'ca-app-pub-9787163762873138/8882654263',
  );

  static AdIds get production => Platform.isIOS ? productionIos : productionAndroid;

  /// Production uniquement pour un build RELEASE (Android ou iOS).
  static bool get usesProduction => kReleaseMode && (Platform.isAndroid || Platform.isIOS);

  static AdIds forBuild() => usesProduction ? production : test();

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
