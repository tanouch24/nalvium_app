import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/widgets/authed_image.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_panel.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import 'session_labels.dart';

/// Historique : uniquement de vraies sessions du backend.
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
        title: Text(l10n.history, style: Theme.of(context).textTheme.headlineMedium),
        toolbarHeight: 72,
      ),
      body: SafeArea(
        child: sessions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(NalviumSpacing.lg),
              child: ErrorPanel(error: e, onRetry: () => ref.invalidate(allSessionsProvider)),
            ),
          ),
          data: (items) => items.isEmpty
              ? EmptyState(icon: Icons.history_rounded, title: l10n.historyEmptyTitle, body: l10n.historyEmptyBody)
              : ListView.separated(
                  padding: const EdgeInsets.all(NalviumSpacing.lg),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: NalviumSpacing.sm),
                  itemBuilder: (context, i) {
                    final s = items[i];
                    return Material(
                      color: NalviumColors.surface,
                      borderRadius: BorderRadius.circular(NalviumSpacing.radiusSmall),
                      child: InkWell(
                        key: Key('history-${s.id}'),
                        borderRadius: BorderRadius.circular(NalviumSpacing.radiusSmall),
                        onTap: () => context.push('/session/${s.id}'),
                        child: Padding(
                          padding: const EdgeInsets.all(NalviumSpacing.md),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: s.firstMediaId == null
                                      ? const ColoredBox(color: NalviumColors.blueSoft, child: Icon(Icons.chat_bubble_outline_rounded, color: NalviumColors.blue))
                                      : AuthedImage(mediaId: s.firstMediaId!),
                                ),
                              ),
                              const SizedBox(width: NalviumSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(sessionTitle(l10n, s), maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: 2),
                                    Text(sessionStatusLabel(l10n, s), style: Theme.of(context).textTheme.bodyMedium),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: NalviumColors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
