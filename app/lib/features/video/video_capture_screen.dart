import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/error_panel.dart';
import '../../domain/video.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import '../../services/video_recorder_service.dart';
import 'video_alternatives.dart';

enum _Phase { initializing, ready, recording, finishing, error }

/// Capture vidéo : 15 secondes maximum, temps restant réel, arrêt manuel, arrêt automatique, annulation.
class VideoCaptureScreen extends ConsumerStatefulWidget {
  const VideoCaptureScreen({super.key});

  @override
  ConsumerState<VideoCaptureScreen> createState() => _VideoCaptureScreenState();
}

class _VideoCaptureScreenState extends ConsumerState<VideoCaptureScreen>
    with WidgetsBindingObserver {
  late final VideoRecorder _recorder = ref.read(videoRecorderFactoryProvider)();
  _Phase _phase = _Phase.initializing;
  Object? _error;
  final _watch = Stopwatch();
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  int _ticks = 0;

  static const _max = Duration(seconds: kMaxVideoSeconds);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    setState(() => _phase = _Phase.initializing);
    try {
      await _recorder.initialize();
      if (mounted) setState(() => _phase = _Phase.ready);
    } on VideoException catch (e) {
      _fail(e);
    }
  }

  void _fail(Object e) {
    if (!mounted) return;
    setState(() {
      _phase = _Phase.error;
      _error = e;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused &&
        (_phase == _Phase.recording || _phase == _Phase.ready)) {
      // L'app quitte l'écran : on abandonne l'enregistrement (rien n'est gardé) et on libère la caméra.
      _ticker?.cancel();
      _watch.stop();
      _recorder.cancel().then((_) => _recorder.dispose());
      if (mounted) setState(() => _phase = _Phase.initializing);
    } else if (state == AppLifecycleState.resumed &&
        _phase == _Phase.initializing) {
      _init();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _recorder.cancel().then((_) => _recorder.dispose());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_phase == _Phase.recording) return _finish();
    if (_phase != _Phase.ready) return;
    try {
      await _recorder.start();
    } on VideoException catch (e) {
      _fail(e);
      return;
    }
    HapticFeedback.mediumImpact();
    _watch
      ..reset()
      ..start();
    _ticks = 0;
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      _ticks++;
      // Le chronomètre réel est un plancher : si l'interface a du retard, le temps affiché ne recule jamais.
      final byTicks = Duration(milliseconds: _ticks * 100);
      final elapsed = byTicks > _watch.elapsed ? byTicks : _watch.elapsed;
      setState(() => _elapsed = elapsed);
      if (elapsed >= _max) _finish(); // arrêt automatique à 15 s
    });
    setState(() {
      _phase = _Phase.recording;
      _elapsed = Duration.zero;
    });
  }

  Future<void> _finish() async {
    if (_phase != _Phase.recording) return;
    _ticker?.cancel();
    _watch.stop();
    final elapsed = _elapsed > _max ? _max : _elapsed;
    setState(() => _phase = _Phase.finishing);
    HapticFeedback.lightImpact();
    try {
      final path = await _recorder.stop();
      if (elapsed.inMilliseconds < kMinVideoMs) {
        throw const VideoException(VideoFailure.tooShort);
      }
      final size = await _sizeOf(path);
      if (size > kMaxVideoBytes) {
        throw const VideoException(VideoFailure.tooLarge);
      }
      if (!mounted) return;
      context.pushReplacement(
        '/video/preview',
        extra: VideoClip(
          path: path,
          duration: elapsed,
          hasAudio: _recorder.hasAudio,
        ),
      );
    } on VideoException catch (e) {
      _fail(e);
    }
  }

  Future<int> _sizeOf(String path) => ref.read(videoFileSizeProvider)(path);

  Future<void> _cancel() async {
    _ticker?.cancel();
    _watch.stop();
    await _recorder.cancel();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_phase == _Phase.error) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: l10n.close,
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Space.gutter),
              child: ErrorPanel(
                error: _error!,
                onRetry: () {
                  setState(() => _error = null);
                  _init();
                },
                secondary: const VideoAlternatives(),
              ),
            ),
          ),
        ),
      );
    }

    final recording = _phase == _Phase.recording;
    final remaining = (_max - _elapsed).inMilliseconds.clamp(
      0,
      _max.inMilliseconds,
    );
    final remainingSeconds = (remaining / 1000).ceil();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_phase != _Phase.initializing)
              Center(child: _recorder.buildPreview())
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(Space.x3),
                    child: Row(
                      children: [
                        _RoundIcon(
                          key: const Key('video-close'),
                          icon: Icons.close_rounded,
                          label: l10n.close,
                          onTap: _cancel,
                        ),
                        const Spacer(),
                        if (!_recorder.hasAudio &&
                            _phase != _Phase.initializing)
                          Container(
                            key: const Key('video-no-sound'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: Space.x3,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(Corner.small),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.mic_off_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.videoNoSound,
                                  style: NalviumText.caption.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: Space.x2),
                        if (_recorder.canSwitchCamera && !recording)
                          _RoundIcon(
                            key: const Key('video-switch'),
                            icon: Icons.cameraswitch_rounded,
                            label: l10n.videoSwitchCamera,
                            onTap: () async {
                              await _recorder.switchCamera();
                              if (mounted) setState(() {});
                            },
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Temps : restant pendant l'enregistrement, limite sinon.
                  Container(
                    key: const Key('video-timer'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Space.x4,
                      vertical: Space.x2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(Corner.medium),
                    ),
                    child: Text(
                      recording
                          ? l10n.videoRemaining(remainingSeconds)
                          : l10n.videoMaxHint,
                      style: NalviumText.title.copyWith(
                        color: Colors.white,
                        fontSize: recording ? 24 : 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.x6),
                  _RecordButton(
                    recording: recording,
                    progress: _elapsed.inMilliseconds / _max.inMilliseconds,
                    busy: _phase != _Phase.ready && !recording,
                    label: recording ? l10n.videoStop : l10n.videoStart,
                    onTap: _toggle,
                  ),
                  const SizedBox(height: Space.x8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black.withValues(alpha: 0.45),
    shape: const CircleBorder(),
    child: IconButton(
      icon: Icon(icon, color: Colors.white),
      tooltip: label,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      onPressed: onTap,
    ),
  );
}

class _RecordButton extends StatelessWidget {
  const _RecordButton({
    required this.recording,
    required this.progress,
    required this.busy,
    required this.label,
    required this.onTap,
  });
  final bool recording;
  final double progress;
  final bool busy;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      key: const Key('record-button'),
      onTap: busy ? null : onTap,
      child: SizedBox(
        width: 92,
        height: 92,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 92,
              height: 92,
              child: CircularProgressIndicator(
                value: recording ? progress.clamp(0.0, 1.0) : 1,
                strokeWidth: 5,
                color: Colors.white,
                backgroundColor: Colors.white24,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: recording ? 34 : 68,
              height: recording ? 34 : 68,
              decoration: BoxDecoration(
                color: recording ? Colors.white : NalviumColors.primary,
                borderRadius: BorderRadius.circular(recording ? 8 : 34),
              ),
              child: recording
                  ? null
                  : const Icon(
                      Icons.videocam_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}
