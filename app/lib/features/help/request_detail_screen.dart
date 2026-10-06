import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exceptions.dart';
import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/authed_image.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/error_panel.dart';
import '../../domain/service_request.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import '../history/session_labels.dart';
import 'request_labels.dart';

/// Détail d'une demande : ce qui a été partagé, rien d'inventé (pas de professionnel, pas de délai).
class RequestDetailScreen extends ConsumerWidget {
  const RequestDetailScreen({super.key, required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final req = ref.watch(requestProvider(requestId));
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(key: const Key('request-back'), onPressed: () => context.pop()),
        title: Text(l10n.requestTitle, style: NalviumText.title),
      ),
      body: SafeArea(
        child: req.when(
          skipLoadingOnReload: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: SingleChildScrollView(padding: const EdgeInsets.all(Space.gutter), child: ErrorPanel(error: e, onRetry: () => ref.invalidate(requestProvider(requestId))))),
          data: (r) => _Body(req: r),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.req});
  final ServiceRequest req;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final color = requestStatusColor(req.status);
    final stop = req.safetyReason ?? req.professionalReason;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.x2, Space.gutter, Space.x10),
      children: [
        Row(children: [
          Icon(requestStatusIcon(req.status), size: 20, color: color),
          const SizedBox(width: 6),
          Flexible(child: Text(requestStatusLabel(l10n, req.status), key: const Key('request-status'), style: NalviumText.title.copyWith(fontSize: 18, color: color))),
        ]),
        if (req.submittedAt != null) Text('${l10n.requestSentOn} ${relativeDate(l10n, req.submittedAt!)}', style: NalviumText.caption),
        const SizedBox(height: Space.x4),
        Semantics(header: true, child: Text(req.summary ?? '', key: const Key('request-summary'), style: NalviumText.titleLarge.copyWith(fontSize: 24, height: 1.25))),
        if (req.equipmentLabel != null) ...[const SizedBox(height: Space.x2), Text(req.equipmentLabel!, key: const Key('request-equipment'), style: NalviumText.body)],
        if (stop != null) ...[
          const SizedBox(height: Space.x4),
          Container(
            padding: const EdgeInsets.all(Space.x4),
            decoration: BoxDecoration(color: NalviumColors.dangerSoft, borderRadius: BorderRadius.circular(Corner.medium)),
            child: Text(stop, key: const Key('request-stop'), style: NalviumText.body.copyWith(color: NalviumColors.textPrimary, fontSize: 15)),
          ),
        ],
        _h(l10n.requestShared),
        // Une seule surface légère : disponibilité (préférence), puis coordonnées.
        Container(
          padding: const EdgeInsets.fromLTRB(Space.x4, Space.x4, Space.x4, Space.x2),
          decoration: BoxDecoration(color: NalviumColors.surface, borderRadius: BorderRadius.circular(Corner.small + 4), border: Border.all(color: NalviumColors.borderSubtle)),
          child: Column(children: [
            _row(Icons.event_outlined, availabilityLabel(l10n, req), key: const Key('request-availability')),
            _row(Icons.person_outline_rounded, [?req.firstName, ?req.phone].join(' · ')),
            _row(Icons.place_outlined, [?req.city, ?req.postalCode].join(' · ')),
            if ((req.email ?? '').isNotEmpty) _row(Icons.mail_outline_rounded, req.email!),
          ]),
        ),
        _h(l10n.requestMedia),
        if (req.mediaIds.isEmpty)
          Text(l10n.helpMediaNone, style: NalviumText.body.copyWith(fontSize: 15))
        else
          Wrap(spacing: Space.x2, runSpacing: Space.x2, children: [
            for (final id in req.mediaIds) ClipRRect(borderRadius: BorderRadius.circular(Corner.small), child: SizedBox(width: 88, height: 88, child: AuthedImage(mediaId: id))),
          ]),
        const SizedBox(height: Space.x6),
        Text(l10n.requestHonest, key: const Key('request-honest'), style: NalviumText.caption.copyWith(color: NalviumColors.textMuted)),
        if (req.status.cancellable) ...[
          const SizedBox(height: Space.x6),
          SecondaryButton(key: const Key('request-cancel'), label: l10n.requestCancel, onPressed: () => _cancel(context, ref)),
        ],
      ],
    );
  }

  Widget _h(String t) => Padding(
    padding: const EdgeInsets.only(top: Space.x6, bottom: Space.x3),
    child: Semantics(header: true, child: Text(t, style: NalviumText.title.copyWith(fontSize: 18.5))),
  );

  Widget _row(IconData i, String t, {Key? key}) => Padding(
    key: key,
    padding: const EdgeInsets.only(bottom: Space.x2),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(i, size: 20, color: NalviumColors.textSecondary),
      const SizedBox(width: Space.x3),
      Expanded(child: Text(t, style: NalviumText.body.copyWith(color: NalviumColors.textPrimary))),
    ]),
  );

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: NalviumColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Corner.large))),
      builder: (sheet) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.gutter, Space.x6, Space.gutter, Space.x6),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l10n.requestCancelTitle, style: NalviumText.titleLarge),
            const SizedBox(height: Space.x3),
            Text(l10n.requestCancelBody, style: NalviumText.body),
            const SizedBox(height: Space.x6),
            DangerButton(key: const Key('request-cancel-confirm'), label: l10n.requestCancelConfirm, onPressed: () => Navigator.of(sheet).pop(true)),
            const SizedBox(height: Space.x2),
            SecondaryButton(key: const Key('request-cancel-keep'), label: l10n.requestKeep, onPressed: () => Navigator.of(sheet).pop(false)),
          ]),
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(serviceRequestsRepositoryProvider).cancel(req.id);
      ref.read(requestsRevisionProvider.notifier).bump();
    } on ApiException {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.requestCancelFail)));
    }
  }
}
