import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exceptions.dart';
import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_theme.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/error_panel.dart';
import '../../domain/session.dart';
import '../../domain/video.dart';
import '../../l10n/app_localizations.dart';
import '../../core/widgets/video_poster.dart';
import '../../services/providers.dart';
import '../video/video_alternatives.dart';
import 'analysis_wait.dart';
import '../../core/analytics/analytics.dart';

/// Point d'entrée d'une nouvelle session : une photo OU une description.
sealed class SessionStart {
  const SessionStart({this.equipmentId});

  /// Équipement de la Maison d'où part le diagnostic (null = diagnostic libre).
  final String? equipmentId;
}

class PhotoStart extends SessionStart {
  const PhotoStart(this.path, {super.equipmentId});
  final String path;
}

class VideoStart extends SessionStart {
  const VideoStart(this.clip, {super.equipmentId});
  final VideoClip clip;
}

class DescriptionStart extends SessionStart {
  const DescriptionStart(this.text, {super.equipmentId});
  final String text;
}

/// Crée la session, envoie la photo/description, attend la VRAIE analyse, puis ouvre l'écran guidé.
/// Jamais de spinner infini : timeout, erreur typée, Réessayer, Annuler.
class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key, required this.start});
  final SessionStart start;

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  String? _sessionId;
  String? _mediaId;
  bool _inputSent = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() => _error = null);
    try {
      final repo = ref.read(sessionsRepositoryProvider);
      final start = widget.start;
      if (_sessionId == null) {
        _sessionId = await repo.createSession(equipmentId: start.equipmentId);
        ref
            .read(analyticsProvider)
            .log(
              AnalyticsEvent.diagnosticStarted,
              source: start is PhotoStart
                  ? 'photo'
                  : (start is VideoStart ? 'video' : 'description'),
            );
      }
      if (start is PhotoStart) {
        _mediaId ??= await repo.uploadPhoto(_sessionId!, start.path);
      } else if (start is VideoStart) {
        _mediaId ??= await repo.uploadVideo(_sessionId!, start.clip.path);
      }
      // L'entrée n'est envoyée qu'une fois ; ensuite on ne fait que relancer l'analyse.
      final TurnInput? input = _inputSent
          ? null
          : switch (start) {
              PhotoStart() => PhotoTurn(_mediaId!),
              VideoStart() => VideoTurn(_mediaId!),
              DescriptionStart(:final text) => DescriptionTurn(text),
            };
      try {
        await repo.sendTurn(_sessionId!, input);
      } on ApiHttpException {
        _inputSent = true; // le serveur a enregistré l'entrée (analyse en échec) : on relancera sans la dupliquer
        rethrow;
      }
      _inputSent = true;
      if (!mounted) return;
      ref.read(sessionsRevisionProvider.notifier).bump();
      context.pushReplacement('/session/$_sessionId');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final start = widget.start;

    final Widget content = _error != null
        ? Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Space.gutter),
              child: ErrorPanel(
                error: _error!,
                onRetry: _error is ApiNotConfigured ? null : _run,
                // Une vidéo qui échoue propose une photo ou une description plutôt qu'un cul-de-sac.
                secondary: start is VideoStart
                    ? const VideoAlternatives()
                    : TertiaryButton(
                        key: const Key('back-home'),
                        label: l10n.backToHome,
                        color: NalviumColors.textSecondary,
                        onPressed: () => context.go('/home'),
                      ),
              ),
            ),
          )
        : AnalysisWait(
            onCancel: () => context.go('/home'),
            title: start is DescriptionStart
                ? l10n.analyzingDescription
                : start is VideoStart
                ? l10n.analyzingVideo
                : null,
            video: start is VideoStart,
            refined: true,
            subject: start is DescriptionStart ? start.text : null,
            photo: start is PhotoStart
                ? Image.file(
                    File(start.path),
                    fit: BoxFit.cover,
                    semanticLabel: l10n.photoSemantics,
                    errorBuilder: (_, _, _) =>
                        const ColoredBox(color: NalviumColors.surfaceSubtle),
                  )
                : start is VideoStart
                ? VideoPoster(path: start.clip.path)
                : null,
          );

    // Barre d'état claire sur fond clair : icônes sombres, appliquées localement (l'aperçu photo précédent
    // laissait des icônes blanches).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: nalviumSystemOverlay,
      child: Scaffold(body: SafeArea(child: content)),
    );
  }
}
