import 'package:flutter/widgets.dart';

/// Façade publicitaire. L'app ne parle qu'à cette interface (les tests utilisent un faux).
abstract interface class AdsService {
  /// Consentement (UMP) puis SDK. Idempotent. Ne lève jamais.
  Future<void> initialize();

  /// Bannière adaptative PERMANENTE de l'accueil (indépendante des pubs plein écran).
  Widget buildHomeBanner();

  /// À appeler quand un NOUVEAU diagnostic démarre : affiche (et attend la fermeture de)
  /// l'interstitiel s'il est dû, et compte le diagnostic. Ne bloque jamais en cas d'échec.
  Future<void> beforeNewDiagnostic();

  /// L'app revient au premier plan ([backgroundFor] = durée passée en arrière-plan).
  Future<void> onAppResumed({required String route, required Duration backgroundFor});

  /// Exécute [action] (ex. caméra système) sans qu'un retour au premier plan déclenche une App Open.
  Future<T> suspendAppOpen<T>(Future<T> Function() action);
}

class NoopAdsService implements AdsService {
  const NoopAdsService();
  @override
  Future<void> initialize() async {}
  @override
  Widget buildHomeBanner() => const SizedBox.shrink();
  @override
  Future<void> beforeNewDiagnostic() async {}
  @override
  Future<void> onAppResumed({required String route, required Duration backgroundFor}) async {}
  @override
  Future<T> suspendAppOpen<T>(Future<T> Function() action) => action();
}
