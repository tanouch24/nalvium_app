import 'dart:io';

import 'package:image_picker/image_picker.dart';

/// Résultat d'une capture. Le fichier reste local au téléphone.
class CapturedPhoto {
  const CapturedPhoto(this.path);
  final String path;
}

class CameraUnavailableException implements Exception {
  const CameraUnavailableException([this.cause]);
  final Object? cause;
}

abstract interface class PhotoCaptureService {
  /// Ouvre la caméra. Retourne null si l'utilisateur annule.
  Future<CapturedPhoto?> takePhoto();

  /// Android peut fermer l'app pendant que l'appareil photo est ouvert (mémoire basse) : la photo prise
  /// est alors récupérable au redémarrage. Retourne null s'il n'y a rien (ou hors Android). Ne lance jamais.
  Future<CapturedPhoto?> recoverLostPhoto();
}

class ImagePickerPhotoCaptureService implements PhotoCaptureService {
  ImagePickerPhotoCaptureService([ImagePicker? picker]) : _picker = picker ?? ImagePicker();
  final ImagePicker _picker;

  @override
  Future<CapturedPhoto?> takePhoto() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 88,
      );
      return file == null ? null : CapturedPhoto(file.path);
    } catch (e) {
      throw CameraUnavailableException(e);
    }
  }

  @override
  Future<CapturedPhoto?> recoverLostPhoto() async {
    if (!Platform.isAndroid) return null;
    try {
      final lost = await _picker.retrieveLostData();
      final file = lost.isEmpty ? null : lost.file;
      if (file == null || !File(file.path).existsSync()) return null;
      return CapturedPhoto(file.path);
    } catch (_) {
      return null;
    }
  }
}

/// VALIDATION SUR APPAREIL UNIQUEMENT (build debug) : renvoie toujours le même fichier de test, sans ouvrir
/// l'application caméra du système (`--dart-define=NALVIUM_DEBUG_PHOTO=/chemin/photo.jpg`).
/// Jamais actif en release (voir providers.dart).
class FixedFilePhotoCaptureService implements PhotoCaptureService {
  const FixedFilePhotoCaptureService(this.path);
  final String path;

  @override
  Future<CapturedPhoto?> takePhoto() async => CapturedPhoto(path);

  @override
  Future<CapturedPhoto?> recoverLostPhoto() async => null;
}
