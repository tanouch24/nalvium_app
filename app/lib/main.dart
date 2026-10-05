import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'app.dart';
import 'core/router/app_router.dart';
import 'core/theme/nalvium_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(nalviumSystemOverlay);
  // Pas de nouvelle tentative automatique : une erreur est montrée tout de suite (avec « Réessayer »).
  runApp(
    ProviderScope(
      retry: (_, _) => null,
      child: NalviumApp(router: _debugRouter()),
    ),
  );
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
