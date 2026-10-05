import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/authed_image.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_panel.dart';
import '../../core/widgets/status_chip.dart';
import '../../domain/session.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import 'session_labels.dart';

/// Historique : uniquement de vraies sessions du backend. Une session active se reprend,
/// une session terminée ouvre son récapitulatif (jamais la conversation brute).
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sessions = ref.watch(allSessionsProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(onPressed: () => context.pop()),
        title: Text(l10n.history, style: NalviumText.titleLarge),
        toolbarHeight: 72,
      ),
      body: SafeArea(
        child: sessions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(Space.gutter),
              child: ErrorPanel(
                error: e,
                onRetry: () => ref.invalidate(allSessionsProvider),
              ),
            ),
          ),
          data: (items) => items.isEmpty
              ? EmptyState(
                  icon: Icons.history_rounded,
                  title: l10n.historyEmptyTitle,
                  body: l10n.historyEmptyBody,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.x8),
                  itemCount: items.length + 1,
                  separatorBuilder: (_, i) => i == 0 ? const SizedBox.shrink() : const Divider(height: 1, thickness: 0.8, color: NalviumColors.borderSubtle),
                  itemBuilder: (context, i) => i == 0
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: Space.x2),
                          child: Text(l10n.historyIntro, key: const Key('history-intro'), style: NalviumText.body),
                        )
                      : _HistoryRow(session: items[i - 1]),
                ),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.session});
  final SessionSummary session;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = session;
    final tone = sessionTone(s.status);
    final color = switch (tone) {
      StatusTone.success => NalviumColors.success,
      StatusTone.danger => NalviumColors.dangerText,
      StatusTone.neutral => NalviumColors.textSecondary,
      StatusTone.info => NalviumColors.primaryText,
    };
    return Semantics(
      button: true,
      child: InkWell(
        key: Key('history-${s.id}'),
        borderRadius: BorderRadius.circular(Corner.medium),
        onTap: () => context.push(s.status == 'active' ? '/session/${s.id}' : '/session/${s.id}/summary'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.x4),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: s.firstMediaId == null
                      ? const ColoredBox(color: NalviumColors.primarySoft, child: Icon(Icons.edit_note_rounded, color: NalviumColors.primary, size: 30))
                      : AuthedImage(mediaId: s.firstMediaId!),
                ),
              ),
              const SizedBox(width: Space.x4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sessionTitle(l10n, s), maxLines: 2, overflow: TextOverflow.ellipsis, style: NalviumText.title.copyWith(fontSize: 18)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(sessionIcon(s.status), size: 16, color: color),
                        const SizedBox(width: 5),
                        Flexible(child: Text(sessionStatusLabel(l10n, s), style: NalviumText.caption.copyWith(color: color, fontWeight: FontWeight.w700))),
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(relativeDate(l10n, s.updatedAt), style: NalviumText.caption.copyWith(color: NalviumColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: NalviumColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
