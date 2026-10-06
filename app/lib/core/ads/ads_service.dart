import 'package:flutter/widgets.dart';

/// Façade publicitaire. L'app ne parle qu'à cette interface (les tests utilisent un faux).
abstract interface class AdsService {
  /// Consentement (UMP) puis SDK. Idempotent. Ne lève jamais.
  Future<void> initialize();

  /// Bannière adaptative PERMANENTE de l'accueil (indépendante des pubs plein écran).
  Widget buildBanner();

  /// À appeler quand un NOUVEAU diagnostic démarre : affiche (et attend la fermeture de)
  /// l'interstitiel s'il est dû, et compte le diagnostic. Ne bloque jamais en cas d'échec.
  Future<void> beforeNewDiagnostic();

  /// L'app revient au premier plan ([backgroundFor] = durée passée en arrière-plan).
  Future<void> onAppResumed({required String route, required Duration backgroundFor});

  /// UMP : un formulaire « options de confidentialité » doit-il être proposé à l'utilisateur (EEE/UK…) ?
  /// Faux si le consentement n'est pas requis ou indisponible. Ne lève jamais.
  Future<bool> privacyOptionsRequired();

  /// Ouvre le formulaire UMP des choix publicitaires. Ne lève jamais ; ne bloque jamais l'app.
  Future<void> showPrivacyOptions();

  /// Exécute [action] (ex. caméra système) sans qu'un retour au premier plan déclenche une App Open.
  Future<T> suspendAppOpen<T>(Future<T> Function() action);
}

class NoopAdsService implements AdsService {
  const NoopAdsService();
  @override
  Future<void> initialize() async {}
  @override
  Widget buildBanner() => const SizedBox.shrink();
  @override
  Future<void> beforeNewDiagnostic() async {}
  @override
  Future<void> onAppResumed({required String route, required Duration backgroundFor}) async {}
  @override
  Future<bool> privacyOptionsRequired() async => false;
  @override
  Future<void> showPrivacyOptions() async {}
  @override
  Future<T> suspendAppOpen<T>(Future<T> Function() action) => action();
}

/// VALIDATION VISUELLE UNIQUEMENT (build debug, `--dart-define=NALVIUM_DEBUG_BANNER=true`) : un bloc de la taille d'une
/// bannière à la place de la vraie pub, pour vérifier la mise en page quand l'appareil n'a pas de réseau publicitaire.
class PlaceholderBannerAdsService extends NoopAdsService {
  const PlaceholderBannerAdsService();
  @override
  Widget buildBanner() => Container(
    key: const Key('ad-banner'),
    height: 60,
    width: double.infinity,
    alignment: Alignment.center,
    color: const Color(0xFFE3E9F2),
    child: const Text('Espace publicitaire (test de mise en page)', style: TextStyle(fontSize: 12, color: Color(0xFF4F5E78), decoration: TextDecoration.none, fontWeight: FontWeight.w400)),
  );
}
