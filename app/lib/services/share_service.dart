import 'dart:typed_data';
import 'dart:ui';

import 'package:share_plus/share_plus.dart';

/// Partage système (feuille iOS / Android) d'une image générée par l'app. Les tests le remplacent par un faux.
abstract interface class ShareService {
  /// [origin] : zone du bouton (ancrage de la feuille sur iPad). Aucune donnée personnelle dans [text].
  Future<void> shareImage(
    Uint8List png, {
    required String fileName,
    required String text,
    Rect? origin,
  });
}

class PlatformShareService implements ShareService {
  const PlatformShareService();

  @override
  Future<void> shareImage(
    Uint8List png, {
    required String fileName,
    required String text,
    Rect? origin,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(png, mimeType: 'image/png')],
        fileNameOverrides: [fileName],
        text: text,
        sharePositionOrigin: origin,
      ),
    );
  }
}
