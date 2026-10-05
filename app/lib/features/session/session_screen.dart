import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exceptions.dart';
import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/widgets/authed_image.dart';
import '../../core/widgets/error_panel.dart';
import '../../domain/diagnosis.dart';
import '../../domain/session.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import '../capture/capture_flow.dart';
import 'views/action_views.dart';

/// Expérience guidée. Le BACKEND est la source de vérité : l'écran se recharge depuis lui
/// (reprise après redémarrage) et l'interface dépend uniquement de `action_type`.
class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  SessionState? _state;
  Object? _error;
  bool _busy = true;
  Future<SessionState> Function()? _lastOp;
  int _countBefore = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final state = await ref.read(sessionsRepositoryProvider).getSession(widget.sessionId);
      if (!mounted) return;
      if (state.pendingAnalysis) {
        // Un message utilisateur attend une réponse (analyse interrompue) : on la relance.
        _apply(state, busyAfter: true);
        await _execute(() => ref.read(sessionsRepositoryProvider).sendTurn(widget.sessionId, null));
      } else {
        _apply(state);
      }
    } on ApiException catch (e) {
      _fail(e);
    }
  }

  void _fail(Object e) {
    if (!mounted) return;
    setState(() {
      _error = e;
      _busy = false;
    });
  }

  void _apply(SessionState state, {bool busyAfter = false}) {
    if (!mounted) return;
    setState(() {
      _state = state;
      _busy = busyAfter;
      _error = null;
    });
    ref.read(sessionsRevisionProvider.notifier).bump();
  }

  Future<void> _execute(Future<SessionState> Function() op) async {
    _lastOp = op;
    _countBefore = _state?.messageCount ?? 0;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _apply(await op());
    } on ApiException catch (e) {
      _fail(e);
    }
  }

  /// Réessayer sans dupliquer : selon ce que le serveur a déjà enregistré.
  Future<void> _retry() async {
    final op = _lastOp;
    if (op == null) return _load();
    final repo = ref.read(sessionsRepositoryProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final fresh = await repo.getSession(widget.sessionId);
      if (fresh.pendingAnalysis) {
        _apply(await repo.sendTurn(widget.sessionId, null));
      } else if (fresh.messageCount > _countBefore) {
        _apply(fresh); // le serveur avait déjà terminé
      } else {
        _apply(await op());
      }
    } on ApiException catch (e) {
      _fail(e);
    }
  }

  void _answer(String text) => _execute(() => ref.read(sessionsRepositoryProvider).sendTurn(widget.sessionId, AnswerTurn(text)));

  void _actionResult(ActionChoice c) =>
      _execute(() => ref.read(sessionsRepositoryProvider).sendTurn(widget.sessionId, ActionResultTurn(c)));

  Future<void> _takePhoto() async {
    final photo = await capturePhoto(context, ref);
    if (photo == null || !mounted) return;
    await _execute(() async {
      final repo = ref.read(sessionsRepositoryProvider);
      final mediaId = await repo.uploadPhoto(widget.sessionId, photo.path);
      return repo.sendTurn(widget.sessionId, PhotoTurn(mediaId));
    });
  }

  void _home() => context.go('/home');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = _state;
    final isStop = state?.next?.actionType == NextActionType.safetyStop && !_busy && _error == null;

    final actions = SessionActions(
      onAnswer: _answer,
      onActionResult: _actionResult,
      onTakePhoto: _takePhoto,
      onHome: _home,
      onRepairOptions: () => context.go('/repair'),
    );

    Widget body;
    if (_error != null) {
      body = _Centered(
        child: ErrorPanel(
          error: _error!,
          onRetry: _retry,
          secondary: TextButton(key: const Key('back-home'), onPressed: _home, child: Text(l10n.backHome)),
        ),
      );
    } else if (_busy || state == null || state.next == null) {
      body = _Thinking(mediaId: state?.latestMediaId, onCancel: _home);
    } else {
      body = _Content(state: state, actions: actions);
    }

    return Scaffold(
      backgroundColor: isStop ? const Color(0xFFFDECEC) : null,
      appBar: AppBar(
        backgroundColor: isStop ? const Color(0xFFFDECEC) : null,
        leading: IconButton(key: const Key('close-session'), icon: const Icon(Icons.close_rounded), tooltip: l10n.close, onPressed: _home),
        title: Text(l10n.appName, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: NalviumColors.blue, letterSpacing: 2.5, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(child: body),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(padding: const EdgeInsets.all(NalviumSpacing.lg), child: child),
      );
}

class _Thinking extends StatelessWidget {
  const _Thinking({this.mediaId, required this.onCancel});
  final String? mediaId;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Centered(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mediaId != null) ...[
            _Photo(mediaId: mediaId!, height: 160),
            const SizedBox(height: NalviumSpacing.lg),
          ],
          const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3)),
          const SizedBox(height: NalviumSpacing.md),
          Text(l10n.analyzingTitle, key: const Key('analyzing-title'), style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: NalviumSpacing.md),
          TextButton(key: const Key('cancel-analysis'), onPressed: onCancel, child: Text(l10n.cancel)),
        ],
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.mediaId, required this.height});
  final String mediaId;
  final double height;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(NalviumSpacing.radius),
        child: SizedBox(height: height, width: double.infinity, child: AuthedImage(mediaId: mediaId)),
      );
}

class _Content extends StatelessWidget {
  const _Content({required this.state, required this.actions});
  final SessionState state;
  final SessionActions actions;

  @override
  Widget build(BuildContext context) {
    final step = state.next!;
    final view = switch (step.actionType) {
      NextActionType.askQuestion => AskQuestionView(key: ValueKey(step.message), step: step, actions: actions),
      NextActionType.requestPhoto => RequestPhotoView(step: step, actions: actions),
      NextActionType.instruction => InstructionView(step: step, actions: actions),
      NextActionType.verification => VerificationView(step: step, actions: actions),
      NextActionType.safetyStop => SafetyStopView(step: step, actions: actions),
      NextActionType.recommendProfessional => ProfessionalView(step: step, actions: actions),
      NextActionType.resolved => ResolvedView(step: step, actions: actions),
    };
    final showPhoto = state.latestMediaId != null && step.actionType != NextActionType.safetyStop;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(NalviumSpacing.lg, NalviumSpacing.sm, NalviumSpacing.lg, NalviumSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showPhoto) ...[
            _Photo(mediaId: state.latestMediaId!, height: 190),
            const SizedBox(height: NalviumSpacing.lg),
          ],
          view,
        ],
      ),
    );
  }
}
