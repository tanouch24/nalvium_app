import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../services/photo_capture_service.dart';
import '../../services/providers.dart';

/// CAMÉRA = ACTION (pas un onglet) : ouvre directement la caméra puis l'aperçu.
Future<void> startPhotoCapture(BuildContext context, WidgetRef ref) async {
  final photo = await _capture(context, ref);
  if (photo == null || !context.mounted) return;
  context.push('/capture/preview', extra: photo.path);
}

Future<CapturedPhoto?> capturePhoto(BuildContext context, WidgetRef ref) =>
    _capture(context, ref);

Future<CapturedPhoto?> _capture(BuildContext context, WidgetRef ref) async {
  try {
    final capture = ref.read(photoCaptureServiceProvider);
    // Le retour de la caméra système ne doit jamais déclencher une pub App Open.
    return await ref.read(adsServiceProvider).suspendAppOpen(capture.takePhoto);
  } on CameraUnavailableException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).cameraError)),
      );
    }
    return null;
  }
}
