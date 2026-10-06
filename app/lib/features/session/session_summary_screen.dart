import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/authed_image.dart';
import '../../core/widgets/error_panel.dart';
import '../house/house_widgets.dart';
import '../../domain/equipment.dart';
import '../../core/widgets/status_chip.dart';
import '../../core/widgets/viewfinder.dart';
import '../../domain/diagnosis.dart';
import '../../domain/session.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import '../history/session_labels.dart';
import 'views/action_views.dart';

/// Récapitulatif d'une session terminée : ce que Nalvium en retient, pas la conversation brute.
class SessionSummaryScreen extends ConsumerWidget {
  const SessionSummaryScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider(sessionId));
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(
          key: const Key('summary-back'),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.summaryTitle, style: NalviumText.title),
      ),
      body: SafeArea(
        child: session.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(Space.gutter),
              child: ErrorPanel(
                error: e,
                onRetry: () => ref.invalidate(sessionProvider(sessionId)),
              ),
            ),
          ),
          data: (s) => _Body(state: s),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});
  final SessionState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final next = state.next;
    final isStop = next?.actionType == NextActionType.safetyStop;
    final tone = sessionTone(state.status);
    final toneColor = switch (tone) {
      StatusTone.success => NalviumColors.success,
      StatusTone.danger => NalviumColors.dangerText,
      StatusTone.neutral => NalviumColors.textSecondary,
      StatusTone.info => NalviumColors.primaryText,
    };
    final statusLabel = switch (state.status) {
      'resolved' => l10n.statusResolved,
      'stopped' => l10n.statusStopped,
      'referred' => l10n.statusReferred,
      _ => l10n.statusActive,
    };
    final category = categoryLabel(l10n, state.category);
    final conclusion = next == null
        ? null
        : (isStop ? stripStopPrefix(next.message) : next.message);
    final observed = next == null
        ? const <String>[]
        : next.observations.where((o) => o.trim().isNotEmpty).take(3).toList();
    final steps = isStop ? const <SessionActionRecord>[] : state.actions;
    final resultBg = switch (tone) {
      StatusTone.success => NalviumColors.successSoft,
      StatusTone.danger => NalviumColors.dangerSoft,
      StatusTone.neutral => NalviumColors.surfaceSubtle,
      StatusTone.info => NalviumColors.primarySoft,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Space.gutter,
        Space.x2,
        Space.gutter,
        Space.x10,
      ),
      children: [
        // ── PROBLÈME ────────────────────────────────────────────────
        if (state.latestMediaId != null && !isStop) ...[
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Corner.large),
                  child: AuthedImage(
                    mediaId: state.latestMediaId!,
                    semanticLabel: l10n.photoSemantics,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(Space.x3),
                  child: ViewfinderCorners(
                    color: Colors.white.withValues(alpha: 0.85),
                    length: 22,
                    stroke: 3,
                    radius: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.x5),
        ],
        Semantics(
          header: true,
          child: Text(
            state.title ?? l10n.untitledProblem,
            key: const Key('summary-title'),
            style: NalviumText.titleLarge.copyWith(fontSize: 28),
          ),
        ),
        const SizedBox(height: Space.x2),
        Row(
          children: [
            Icon(sessionIcon(state.status), size: 18, color: toneColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                [
                  statusLabel,
                  if (category.isNotEmpty) category,
                  if (state.updatedAt != null)
                    relativeDate(l10n, state.updatedAt!),
                ].join(' · '),
                key: const Key('summary-meta'),
                style: NalviumText.caption.copyWith(
                  color: toneColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.x3),
        _HouseLink(state: state),
        if (observed.isNotEmpty) ...[
          const SizedBox(height: Space.x3),
          Text(
            observed.join(' · '),
            key: const Key('summary-observed'),
            style: NalviumText.body.copyWith(fontSize: 15.5),
          ),
        ],

        // ── CE QU'ON A FAIT ─────────────────────────────────────────
        if (steps.isNotEmpty) ...[
          const SizedBox(height: Space.x8),
          _Heading(l10n.summaryDone),
          const SizedBox(height: Space.x3),
          for (final a in steps) _StepRow(a),
        ],

        // ── RÉSULTAT ────────────────────────────────────────────────
        if (conclusion != null && conclusion.isNotEmpty) ...[
          const SizedBox(height: Space.x8),
          _Heading(l10n.summaryResult),
          const SizedBox(height: Space.x3),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Space.x5),
            decoration: BoxDecoration(
              color: resultBg,
              borderRadius: BorderRadius.circular(Corner.medium),
            ),
            child: Text(
              conclusion,
              key: const Key('summary-conclusion'),
              style: NalviumText.bodyLarge.copyWith(
                fontSize: 17.5,
                height: 1.5,
                color: isStop
                    ? NalviumColors.dangerText
                    : NalviumColors.textPrimary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Équipement lié (pastille) ou proposition discrète « Ajouter à votre maison ». Jamais imposé.
class _HouseLink extends StatelessWidget {
  const _HouseLink({required this.state});
  final SessionState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final eq = state.equipment;
    if (eq != null) {
      final kind = EquipmentCatalog.of(eq.equipmentType);
      final label = [eq.displayName, ?eq.brand, ?eq.roomName].join(' · ');
      return Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          button: true,
          label: '${l10n.eqLinkedTo} : $label',
          excludeSemantics: true,
          child: InkWell(
            key: const Key('summary-equipment'),
            borderRadius: BorderRadius.circular(Corner.small),
            onTap: () => context.push('/equipment/${eq.id}'),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InfoPill(icon: kind.icon, label: label),
              ),
            ),
          ),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        key: const Key('summary-add-house'),
        onPressed: () => context.push('/session/${state.id}/house'),
        icon: const Icon(Icons.house_outlined, size: 20),
        label: Text(l10n.eqLinkAdd),
        style: TextButton.styleFrom(
          foregroundColor: NalviumColors.primaryText,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: Space.x3),
          textStyle: NalviumText.button.copyWith(fontSize: 16),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text, style: NalviumText.title.copyWith(fontSize: 19)),
  );
}

class _StepRow extends StatelessWidget {
  const _StepRow(this.action);
  final SessionActionRecord action;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (IconData icon, Color color, String label) = switch (action.status) {
      'done' => (
        Icons.check_circle_rounded,
        NalviumColors.success,
        l10n.stepDone,
      ),
      'failed' => (
        Icons.error_outline_rounded,
        NalviumColors.warning,
        l10n.stepFailed,
      ),
      'mismatch' => (
        Icons.help_outline_rounded,
        NalviumColors.warning,
        l10n.stepMismatch,
      ),
      _ => (
        Icons.radio_button_unchecked_rounded,
        NalviumColors.textMuted,
        l10n.stepPending,
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: Space.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.instruction,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: NalviumText.body.copyWith(
                    color: NalviumColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  style: NalviumText.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
