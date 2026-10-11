import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/local_store.dart';
import 'services/providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/nalvium_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installErrorLogging();
  final prefs = await SharedPreferences.getInstance();
  SystemChrome.setSystemUIOverlayStyle(nalviumSystemOverlay);
  // Téléphone, portrait uniquement.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Pas de nouvelle tentative automatique : une erreur est montrée tout de suite (avec « Réessayer »).
  runApp(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [localStoreProvider.overrideWithValue(LocalStore(prefs))],
      child: NalviumApp(router: _debugRouter()),
    ),
  );
}

/// Erreurs non rattrapées : journalisées (console de développement), jamais de fermeture de l'app.
/// Aucun service tiers : rien ne quitte le téléphone.
@visibleForTesting
void installErrorLogging() {
  FlutterError.onError = (details) {
    if (kDebugMode) FlutterError.presentError(details);
    debugPrint('[Nalvium] FlutterError: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[Nalvium] uncaught: $error');
    return true; // erreur traitée : l'app continue
  };
}

/// VALIDATION VISUELLE UNIQUEMENT (build debug) : ouvre l'aperçu photo avec un fichier de test
/// (`--dart-define=NALVIUM_DEBUG_PREVIEW=/chemin/image.jpg`) sans passer par l'application caméra du
/// système. Absent des builds release (kDebugMode = false).
GoRouter? _debugRouter() {
  const path = String.fromEnvironment('NALVIUM_DEBUG_PREVIEW');
  if (kDebugMode && path.isNotEmpty) {
    return buildRouter(initialLocation: '/capture/preview', initialExtra: path);
  }
  return null;
}
