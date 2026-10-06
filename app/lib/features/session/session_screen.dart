import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exceptions.dart';
import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/widgets/authed_image.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/error_panel.dart';
import '../../core/widgets/motion.dart';
import '../../domain/diagnosis.dart';
import '../../domain/session.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import '../capture/analysis_wait.dart';
import '../capture/capture_flow.dart';
import '../history/session_labels.dart';
import 'context_header.dart';
import '../../domain/community.dart';
import '../community/compose_post_screen.dart';
import '../house/manual_citation.dart';
import 'views/action_views.dart';
import '../../core/analytics/analytics.dart';

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
      final state = await ref
          .read(sessionsRepositoryProvider)
          .getSession(widget.sessionId);
      if (!mounted) return;
      if (state.pendingAnalysis) {
        // Un message utilisateur attend une réponse (analyse interrompue) : on la relance.
        _apply(state, busyAfter: true);
        await _execute(
          () => ref
              .read(sessionsRepositoryProvider)
              .sendTurn(widget.sessionId, null),
        );
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
    final before = _state?.next?.actionType;
    final after = state.next?.actionType;
    if (after != before) {
      if (after == NextActionType.safetyStop) {
        ref.read(analyticsProvider).log(AnalyticsEvent.safetyStop);
      } else if (after == NextActionType.resolved) {
        ref.read(analyticsProvider).log(AnalyticsEvent.diagnosticResolved);
      }
    }
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

  void _answer(String text) => _execute(
    () => ref
        .read(sessionsRepositoryProvider)
        .sendTurn(widget.sessionId, AnswerTurn(text)),
  );

  void _actionResult(ActionChoice c) => _execute(
    () => ref
        .read(sessionsRepositoryProvider)
        .sendTurn(widget.sessionId, ActionResultTurn(c)),
  );

  Future<void> _takePhoto() async {
    final photo = await capturePhoto(context, ref);
    if (photo == null || !mounted) return;
    await _execute(() async {
      final repo = ref.read(sessionsRepositoryProvider);
      final mediaId = await repo.uploadPhoto(widget.sessionId, photo.path);
      return repo.sendTurn(widget.sessionId, PhotoTurn(mediaId));
    });
  }

  /// L'utilisateur a rattaché ce diagnostic à un équipement depuis l'écran de résolution.
  bool _linked = false;

  void _home() => context.go('/home');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = _state;
    final isStop =
        state?.next?.actionType == NextActionType.safetyStop &&
        !_busy &&
        _error == null;

    final actions = SessionActions(
      onAnswer: _answer,
      onActionResult: _actionResult,
      onTakePhoto: _takePhoto,
      onHome: _home,
      onRepairOptions: () => context.push('/help/new?session=${widget.sessionId}'),
      onSummary: () => context.push('/session/${widget.sessionId}/summary'),
      onShareSolution: state == null ? null : () => context.push('/community/new', extra: ComposeArgs(draft: CommunityDraft.fromSession(state))),
      onSaveEquipment: state != null && state.equipment == null && !_linked
          ? () async {
              final linked = await context.push<bool>('/session/${widget.sessionId}/house');
              if (linked == true && mounted) setState(() => _linked = true);
            }
          : null,
    );

    Widget body;
    if (_error != null) {
      body = Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Space.gutter),
          child: ErrorPanel(
            error: _error!,
            onRetry: _retry,
            secondary: TertiaryButton(
              key: const Key('back-home'),
              label: l10n.backToHome,
              color: NalviumColors.textSecondary,
              onPressed: _home,
            ),
          ),
        ),
      );
    } else if (_busy || state == null || state.next == null) {
      body = AnalysisWait(
        onCancel: _home,
        refined: true,
        lightweight: true,
        photo: state?.latestMediaId == null
            ? null
            : AuthedImage(
                mediaId: state!.latestMediaId!,
                semanticLabel: l10n.photoSemantics,
              ),
      );
    } else {
      body = _Content(state: state, actions: actions);
    }

    final bg = isStop
        ? NalviumColors.dangerBackground
        : NalviumColors.background;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          key: const Key('close-session'),
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.close,
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: _home,
        ),
      ),
      body: SafeArea(child: body),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.state, required this.actions});
  final SessionState state;
  final SessionActions actions;

  @override
  Widget build(BuildContext context) {
    final step = state.next!;
    final type = step.actionType;
    final view = switch (type) {
      NextActionType.askQuestion => AskQuestionView(
        key: ValueKey('ask-${state.messageCount}'),
        step: step,
        actions: actions,
      ),
      NextActionType.requestPhoto => RequestPhotoView(
        key: ValueKey('photo-${state.messageCount}'),
        step: step,
        actions: actions,
        previousMediaId: state.latestMediaId,
          previousIsVideo: state.latestMediaIsVideo,
      ),
      NextActionType.instruction => InstructionView(
        key: ValueKey('instr-${state.messageCount}'),
        step: step,
        actions: actions,
      ),
      NextActionType.verification => VerificationView(
        key: ValueKey('verif-${state.messageCount}'),
        step: step,
        actions: actions,
      ),
      NextActionType.safetyStop => SafetyStopView(step: step, actions: actions),
      NextActionType.recommendProfessional => ProfessionalView(
        step: step,
        actions: actions,
      ),
      NextActionType.resolved => ResolvedView(
        step: step,
        actions: actions,
        problemTitle: state.title,
      ),
    };
    // Contexte constant (vignette + titre + catégorie). REQUEST_PHOTO montre déjà la photo (paire), RESOLVED
    // et SAFETY_STOP ont leur propre composition.
    final showContext = switch (type) {
      NextActionType.safetyStop ||
      NextActionType.requestPhoto ||
      NextActionType.resolved => false,
      _ => state.latestMediaId != null || (state.title ?? '').trim().isNotEmpty,
    };

    // Étapes guidées alignées sur la question (en-tête compact) ; les autres écrans gardent leur composition.
    final guided = const {
      NextActionType.askQuestion,
      NextActionType.instruction,
      NextActionType.verification,
      NextActionType.recommendProfessional,
    }.contains(type);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.x2,
        Space.gutter,
        Space.x8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showContext) ...[
            ContextHeader(
              compact: guided,
              isVideo: state.latestMediaIsVideo,
              mediaId: state.latestMediaId,
              title: state.title,
              category: state.equipment != null
                  ? [state.equipment!.displayName, ?state.equipment!.roomName].join(' · ')
                  : categoryLabel(AppLocalizations.of(context), state.category),
            ),
            SizedBox(height: guided ? Space.x6 : Space.x8),
          ],
          if (step.manual != null && type != NextActionType.safetyStop) ...[
            ManualCitationLine(citation: step.manual!, equipmentId: state.equipment?.id),
            const SizedBox(height: Space.x4),
          ],
          AnimatedSwitcher(
            duration: motionDuration(
              context,
              const Duration(milliseconds: 280),
            ),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.02),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            layoutBuilder: (current, previous) => Stack(
              alignment: Alignment.topCenter,
              children: [...previous, ?current],
            ),
            child: KeyedSubtree(
              key: ValueKey('${type.name}-${state.messageCount}'),
              child: view,
            ),
          ),
          // Action secondaire discrète, commune à tous les écrans de guidage (une seule définition).
          if (const {
            NextActionType.askQuestion,
            NextActionType.requestPhoto,
            NextActionType.instruction,
            NextActionType.verification,
          }.contains(type))
            Padding(
              padding: const EdgeInsets.only(top: Space.x1),
              child: TertiaryButton(
                key: const Key('ask-for-help'),
                label: AppLocalizations.of(context).helpAsk,
                color: NalviumColors.textSecondary,
                onPressed: actions.onRepairOptions,
              ),
            ),
        ],
      ),
    );
  }
}
