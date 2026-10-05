/// Limites de la vidéo V1 (identiques côté serveur : 15 s + 1 s de tolérance, 30 Mo).
const kMaxVideoSeconds = 15;
const kMinVideoMs = 1000;
const kMaxVideoBytes = 30 * 1024 * 1024;

/// Une vidéo enregistrée, encore LOCALE (jamais envoyée avant « Utiliser cette vidéo »).
class VideoClip {
  const VideoClip({required this.path, required this.duration, required this.hasAudio});
  final String path;
  final Duration duration;

  /// false si le micro a été refusé : la vidéo est alors sans son (et on le dit honnêtement).
  final bool hasAudio;
}

enum VideoFailure {
  /// Caméra refusée.
  cameraDenied,

  /// Caméra occupée / absente / erreur matérielle.
  cameraUnavailable,

  /// Moins d'une seconde.
  tooShort,

  /// Fichier au-delà de la limite.
  tooLarge,
}

class VideoException implements Exception {
  const VideoException(this.failure);
  final VideoFailure failure;
  @override
  String toString() => 'VideoException($failure)';
}

String formatClock(Duration d) {
  final s = d.inSeconds;
  return '${(s ~/ 60)}:${(s % 60).toString().padLeft(2, '0')}';
}
