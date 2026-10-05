import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exceptions.dart';
import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/widgets/error_panel.dart';
import '../../domain/session.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';

/// Point d'entrée d'une nouvelle session : une photo OU une description.
sealed class SessionStart {
  const SessionStart();
}

class PhotoStart extends SessionStart {
  const PhotoStart(this.path);
  final String path;
}

class DescriptionStart extends SessionStart {
  const DescriptionStart(this.text);
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
  bool _showSubtitle = false;
  bool _showSlow = false;
  final _timers = <Timer>[];

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  Future<void> _run() async {
    for (final t in _timers) {
      t.cancel();
    }
    _timers
      ..clear()
      ..add(Timer(const Duration(seconds: 5), () => mounted ? setState(() => _showSubtitle = true) : null))
      ..add(Timer(const Duration(seconds: 25), () => mounted ? setState(() => _showSlow = true) : null));
    setState(() {
      _error = null;
      _showSubtitle = false;
      _showSlow = false;
    });
    try {
      final repo = ref.read(sessionsRepositoryProvider);
      final start = widget.start;
      _sessionId ??= await repo.createSession();
      if (start is PhotoStart) {
        _mediaId ??= await repo.uploadPhoto(_sessionId!, start.path);
      }
      // L'entrée n'est envoyée qu'une fois ; ensuite on ne fait que relancer l'analyse.
      final TurnInput? input = _inputSent
          ? null
          : switch (start) {
              PhotoStart() => PhotoTurn(_mediaId!),
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
      for (final t in _timers) {
        t.cancel();
      }
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final start = widget.start;

    final Widget content = _error != null
        ? ErrorPanel(
            error: _error!,
            onRetry: _error is ApiNotConfigured ? null : _run,
            secondary: TextButton(
              key: const Key('back-home'),
              onPressed: () => context.go('/home'),
              child: Text(l10n.backHome),
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (start is PhotoStart)
                ClipRRect(
                  borderRadius: BorderRadius.circular(NalviumSpacing.radius),
                  child: SizedBox(
                    height: 220,
                    width: 220,
                    child: Image.file(File(start.path), fit: BoxFit.cover, errorBuilder: (_, _, _) => const ColoredBox(color: NalviumColors.greyLight)),
                  ),
                ),
              if (start is PhotoStart) const SizedBox(height: NalviumSpacing.xl),
              const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 3)),
              const SizedBox(height: NalviumSpacing.lg),
              Text(l10n.analyzingTitle, key: const Key('analyzing-title'), style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: NalviumSpacing.sm),
              AnimatedOpacity(
                opacity: _showSubtitle ? 1 : 0,
                duration: const Duration(milliseconds: 400),
                child: Text(_showSlow ? l10n.analyzingSlow : l10n.analyzingSubtitle, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
              ),
              const SizedBox(height: NalviumSpacing.xl),
              TextButton(key: const Key('cancel-analysis'), onPressed: () => context.go('/home'), child: Text(l10n.cancel)),
            ],
          );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(NalviumSpacing.lg),
            child: content,
          ),
        ),
      ),
    );
  }
}
