import 'package:shared_preferences/shared_preferences.dart';

/// Compte les diagnostics DÉMARRÉS (pas les reprises de session).
abstract interface class DiagnosticCounter {
  Future<int> count();
  Future<void> increment();
}

class PrefsDiagnosticCounter implements DiagnosticCounter {
  static const key = 'nalvium.diagnostics_started';

  @override
  Future<int> count() async => (await SharedPreferences.getInstance()).getInt(key) ?? 0;

  @override
  Future<void> increment() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, (prefs.getInt(key) ?? 0) + 1);
  }
}

/// Règles des publicités plein écran (logique pure, testée) :
///  • Diagnostic n°1 : aucune pub. À partir du n°2 : un interstitiel AVANT chaque NOUVEAU diagnostic.
///  • Jamais au milieu d'une session. Reprendre une session n'est pas un nouveau diagnostic.
///  • App Open : à l'ouverture de l'app, et au retour d'arrière-plan (≥ 30 s) seulement depuis l'accueil.
///  • Un délai minimal sépare deux pubs plein écran ; la bannière de l'accueil en est indépendante.
class AdPolicy {
  AdPolicy({
    required this.counter,
    this.cooldown = const Duration(seconds: 60),
    this.minBackground = const Duration(seconds: 30),
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final DiagnosticCounter counter;
  final Duration cooldown;
  final Duration minBackground;
  final DateTime Function() _now;
  DateTime? _lastFullscreen;

  bool get _cooling => _lastFullscreen != null && _now().difference(_lastFullscreen!) < cooldown;

  void recordFullscreenShown() => _lastFullscreen = _now();

  /// Faut-il un interstitiel avant ce nouveau diagnostic ? (n°1 → non, n°2+ → oui hors délai)
  Future<bool> interstitialDueForNewDiagnostic() async => (await counter.count()) >= 1 && !_cooling;

  Future<void> recordDiagnosticStarted() => counter.increment();

  /// Écrans où AUCUNE pub plein écran ne doit apparaître (session en cours, capture, saisie).
  static bool isInsideSession(String route) =>
      route.startsWith('/session') || route.startsWith('/analyze') || route.startsWith('/capture') || route.startsWith('/describe') || route.startsWith('/video');

  /// [backgroundFor] null = démarrage à froid.
  bool appOpenAllowed({required String route, Duration? backgroundFor, bool externalIntent = false}) {
    if (externalIntent || isInsideSession(route) || _cooling) return false;
    if (backgroundFor != null && backgroundFor < minBackground) return false;
    return true;
  }
}
