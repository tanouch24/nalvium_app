import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';

import '../domain/video.dart';

/// Enregistreur vidéo (interface testable). La caméra et le micro ne sont demandés qu'à l'ouverture de l'écran « Filmer ».
abstract interface class VideoRecorder {
  /// Ouvre la caméra. Lance [VideoException] (cameraDenied / cameraUnavailable).
  /// Si le micro est refusé mais pas la caméra : continue SANS audio ([hasAudio] = false).
  Future<void> initialize();
  bool get hasAudio;
  bool get canSwitchCamera;
  Future<void> switchCamera();
  Widget buildPreview();
  Future<void> start();

  /// Arrête et retourne le chemin du fichier enregistré.
  Future<String> stop();

  /// Abandonne un enregistrement en cours sans rien garder.
  Future<void> cancel();
  Future<void> dispose();
}

/// Implémentation `camera` : 720p, ~3 Mb/s vidéo + 96 kb/s audio (≈ 5 Mo pour 15 s) ; aucune localisation n'est écrite.
class CameraVideoRecorder implements VideoRecorder {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _index = 0;
  bool _audio = true;
  bool _recording = false;

  @override
  bool get hasAudio => _audio;

  @override
  bool get canSwitchCamera => _cameras.length > 1;

  @override
  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
    } on CameraException catch (e) {
      throw VideoException(_map(e));
    }
    if (_cameras.isEmpty) throw const VideoException(VideoFailure.cameraUnavailable);
    _index = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
    if (_index < 0) _index = 0;
    await _open(audio: true);
  }

  Future<void> _open({required bool audio}) async {
    await _controller?.dispose();
    final controller = CameraController(
      _cameras[_index],
      ResolutionPreset.high,
      enableAudio: audio,
      videoBitrate: 3000000,
      audioBitrate: 96000,
    );
    _controller = controller;
    try {
      await controller.initialize();
      _audio = audio;
    } on CameraException catch (e) {
      await controller.dispose();
      _controller = null;
      if (audio && (e.code == 'AudioAccessDenied' || e.code == 'AudioAccessDeniedWithoutPrompt' || e.code == 'AudioAccessRestricted')) {
        // Micro refusé, caméra autorisée : on continue sans son (le flux ne plante pas).
        return _open(audio: false);
      }
      throw VideoException(_map(e));
    }
  }

  VideoFailure _map(CameraException e) => switch (e.code) {
        'CameraAccessDenied' || 'CameraAccessDeniedWithoutPrompt' || 'CameraAccessRestricted' => VideoFailure.cameraDenied,
        _ => VideoFailure.cameraUnavailable,
      };

  @override
  Future<void> switchCamera() async {
    if (!canSwitchCamera || _recording) return;
    _index = (_index + 1) % _cameras.length;
    await _open(audio: _audio);
  }

  @override
  Widget buildPreview() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return const SizedBox.shrink();
    return CameraPreview(c);
  }

  @override
  Future<void> start() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) throw const VideoException(VideoFailure.cameraUnavailable);
    try {
      await c.startVideoRecording();
      _recording = true;
    } on CameraException {
      throw const VideoException(VideoFailure.cameraUnavailable);
    }
  }

  @override
  Future<String> stop() async {
    final c = _controller;
    if (c == null || !_recording) throw const VideoException(VideoFailure.cameraUnavailable);
    try {
      final file = await c.stopVideoRecording();
      _recording = false;
      return file.path;
    } on CameraException {
      _recording = false;
      throw const VideoException(VideoFailure.cameraUnavailable);
    }
  }

  @override
  Future<void> cancel() async {
    final c = _controller;
    if (c == null || !_recording) return;
    try {
      final file = await c.stopVideoRecording();
      await File(file.path).delete();
    } catch (_) {
      // rien à garder, rien à signaler
    } finally {
      _recording = false;
    }
  }

  @override
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}
