import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../services/photo_capture_service.dart';
import '../../services/providers.dart';

/// CAMÉRA = ACTION (pas un onglet) : ouvre directement la caméra puis l'aperçu.
/// [equipmentId] : diagnostic lancé depuis une fiche équipement (la session sera liée à cet équipement).
/// Sans accord IA, l'accord est demandé AVANT d'ouvrir la caméra (la photo ne serait pas utilisable).
Future<void> startPhotoCapture(BuildContext context, WidgetRef ref, {String? equipmentId}) async {
  if (!ref.read(aiConsentProvider)) {
    context.go('/consent');
    return;
  }
  final photo = await _capture(context, ref);
  if (photo == null || !context.mounted) return;
  context.push(
    equipmentId == null ? '/capture/preview' : '/capture/preview?equipment=$equipmentId',
    extra: photo.path,
  );
}

Future<CapturedPhoto?> capturePhoto(BuildContext context, WidgetRef ref) =>
    _capture(context, ref);

Future<CapturedPhoto?> _capture(BuildContext context, WidgetRef ref) async {
  try {
    final capture = ref.read(photoCaptureServiceProvider);
    return await capture.takePhoto();
  } on CameraUnavailableException {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).cameraError)),
      );
    }
    return null;
  }
}
