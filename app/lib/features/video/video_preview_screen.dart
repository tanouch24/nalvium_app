import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/buttons.dart';
import '../../domain/video.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import '../capture/analysis_screen.dart';

/// Aperçu : lecture / pause, durée, puis « Utiliser cette vidéo » ou « Refilmer ». Aucun montage, aucun filtre.
class VideoPreviewScreen extends ConsumerStatefulWidget {
  const VideoPreviewScreen({super.key, required this.clip, this.equipmentId});
  final String? equipmentId;
  final VideoClip clip;

  @override
  ConsumerState<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends ConsumerState<VideoPreviewScreen> {
  VideoPlayerController? _controller;
  bool _playbackFailed = false;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.file(File(widget.clip.path));
      _controller = c;
      await c.initialize();
      await c.setLooping(true);
      c.addListener(() {
        if (mounted) setState(() {});
      });
      if (mounted) setState(() {});
    } catch (_) {
      // Lecture impossible : la vidéo est quand même enregistrée, on le dit et on laisse continuer.
      if (mounted) setState(() => _playbackFailed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    HapticFeedback.selectionClick();
    c.value.isPlaying ? c.pause() : c.play();
  }

  /// Nouveau diagnostic : interstitiel éventuel (à partir du n°2, compteur global), puis l'analyse démarre.
  Future<void> _use() async {
    if (_starting) return;
    setState(() => _starting = true);
    await _controller?.pause();
    await ref.read(adsServiceProvider).beforeNewDiagnostic();
    if (!mounted) return;
    context.pushReplacement('/analyze', extra: VideoStart(widget.clip, equipmentId: widget.equipmentId));
  }

  Future<void> _refilm() async {
    await _controller?.pause();
    try {
      File(widget.clip.path).deleteSync(); // la vidéo refaite n'est plus utile : on ne garde rien
    } catch (_) {}
    if (mounted) context.pushReplacement(widget.equipmentId == null ? '/video/capture' : '/video/capture?equipment=${widget.equipmentId}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = _controller;
    final ready = c != null && c.value.isInitialized;
    final playing = ready && c.value.isPlaying;

    final video = Stack(
      fit: StackFit.expand,
      children: [
        if (ready)
          Center(child: AspectRatio(key: const Key('video-preview'), aspectRatio: c.value.aspectRatio, child: VideoPlayer(c)))
        else if (_playbackFailed)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(Space.gutter),
              child: Text(l10n.videoCannotPlay, key: const Key('video-cannot-play'), textAlign: TextAlign.center, style: NalviumText.body.copyWith(color: Colors.white70)),
            ),
          )
        else
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        if (ready)
          Center(
            child: Semantics(
              button: true,
              label: playing ? l10n.videoPause : l10n.videoPlay,
              child: GestureDetector(
                key: const Key('video-play-toggle'),
                behavior: HitTestBehavior.opaque,
                onTap: _togglePlay,
                child: AnimatedOpacity(
                  opacity: playing ? 0 : 1,
                  duration: const Duration(milliseconds: 180),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 44),
                  ),
                ),
              ),
            ),
          ),
        SafeArea(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(Space.x3),
              child: Material(
                color: Colors.black.withValues(alpha: 0.38),
                shape: const CircleBorder(),
                child: IconButton(
                  key: const Key('close-preview'),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  tooltip: l10n.close,
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: Space.x4,
          bottom: Space.x3,
          child: Container(
            key: const Key('video-duration'),
            padding: const EdgeInsets.symmetric(horizontal: Space.x3, vertical: 4),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(Corner.small)),
            child: Text(formatClock(widget.clip.duration), style: NalviumText.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: NalviumColors.textPrimary,
        body: Column(
          children: [
            // Zone vidéo de hauteur BORNÉE : une vidéo portrait ne doit jamais pousser les actions hors écran.
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.5, child: video),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(color: NalviumColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(Corner.large))),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(Space.gutter, Space.x6, Space.gutter, Space.x4 + MediaQuery.paddingOf(context).bottom),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.videoPreviewTitle, style: NalviumText.title),
                      const SizedBox(height: Space.x1),
                      Text(l10n.videoPreviewTip, style: NalviumText.body.copyWith(fontSize: 15)),
                      if (!widget.clip.hasAudio) ...[
                        const SizedBox(height: Space.x2),
                        Row(children: [
                          const Icon(Icons.mic_off_rounded, size: 16, color: NalviumColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(child: Text(l10n.videoNoAudioNote, key: const Key('video-no-audio-note'), style: NalviumText.caption)),
                        ]),
                      ],
                      const SizedBox(height: Space.x5),
                      PrimaryButton(key: const Key('use-video'), label: l10n.useVideo, loading: _starting, onPressed: _use),
                      const SizedBox(height: Space.x2),
                      SecondaryButton(key: const Key('refilm-video'), label: l10n.refilm, icon: Icons.replay_rounded, onPressed: _refilm),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
