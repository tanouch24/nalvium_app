import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/buttons.dart';
import '../../domain/service_request.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import '../history/session_labels.dart';
import 'request_labels.dart';

/// Dépannage : un seul point d'entrée, puis uniquement les VRAIES demandes de l'utilisateur.
class RepairScreen extends ConsumerWidget {
  const RepairScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final requests = ref.watch(requestsProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: Space.gutter,
        title: Text(l10n.repairTitle, style: NalviumText.titleLarge),
        toolbarHeight: 72,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(requestsProvider);
            await ref.read(requestsProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(Space.gutter, Space.x2, Space.gutter, Space.x10),
            children: [
              Container(
                padding: const EdgeInsets.all(Space.x5),
                decoration: BoxDecoration(color: NalviumColors.primarySoft, borderRadius: BorderRadius.circular(Corner.large - 4)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Semantics(header: true, child: Text(l10n.repairHeadline, key: const Key('repair-headline'), style: NalviumText.titleLarge.copyWith(fontSize: 25, height: 1.2))),
                  const SizedBox(height: Space.x2 + 2),
                  Text(l10n.repairHeadlineBody, style: NalviumText.body.copyWith(color: NalviumColors.textPrimary, height: 1.45)),
                  const SizedBox(height: Space.x5),
                  PrimaryButton(key: const Key('repair-ask'), label: l10n.repairAsk, icon: Icons.support_agent_rounded, onPressed: () => context.push('/help/new')),
                ]),
              ),
              const SizedBox(height: Space.x6 + 4),
              Semantics(header: true, child: Text(l10n.repairYourRequests, style: NalviumText.title.copyWith(fontSize: 19))),
              const SizedBox(height: Space.x3),
              requests.when(
                skipLoadingOnReload: true,
                loading: () => const Padding(padding: EdgeInsets.all(Space.x6), child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Column(children: [
                  Text(l10n.repairLoadFail, key: const Key('repair-load-fail'), style: NalviumText.body),
                  TertiaryButton(key: const Key('retry'), label: l10n.retry, onPressed: () => ref.invalidate(requestsProvider)),
                ]),
                data: (items) => items.isEmpty
                    ? Text(l10n.repairNoRequests, key: const Key('repair-empty'), style: NalviumText.body)
                    : Column(children: [for (final r in items) _RequestCard(req: r)]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.req});
  final ServiceRequest req;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = requestStatusColor(req.status);
    final date = relativeDate(l10n, req.submittedAt ?? req.createdAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x2 + 2),
      child: Material(
        color: NalviumColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Corner.small + 4), side: const BorderSide(color: NalviumColors.borderSubtle)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('request-${req.id}'),
          onTap: () => context.push('/requests/${req.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.x4, vertical: Space.x3 + 2),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(req.summary ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: NalviumText.title.copyWith(fontSize: 17.5, height: 1.25)),
                  if (req.equipmentLabel != null) Text(req.equipmentLabel!, maxLines: 1, overflow: TextOverflow.ellipsis, style: NalviumText.caption),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(requestStatusIcon(req.status), size: 16, color: color),
                    const SizedBox(width: 5),
                    Flexible(child: Text(requestStatusLabel(l10n, req.status), style: NalviumText.caption.copyWith(color: color, fontWeight: FontWeight.w700))),
                  ]),
                  Text([date, ?req.city].join(' · '), style: NalviumText.caption.copyWith(color: NalviumColors.textMuted, fontSize: 13)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: NalviumColors.textMuted),
            ]),
          ),
        ),
      ),
    );
  }
}
