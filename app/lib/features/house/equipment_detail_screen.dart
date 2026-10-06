import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exceptions.dart';
import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/authed_image.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/choice_tile.dart';
import '../../core/widgets/error_panel.dart';
import '../../domain/equipment.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import '../capture/capture_flow.dart';
import '../history/session_labels.dart';
import 'house_widgets.dart';
import 'manual_section.dart';
import 'reference_help.dart';

/// Fiche équipement : sa photo, ce qu'on en sait, les problèmes déjà traités, et l'action principale.
class EquipmentDetailScreen extends ConsumerWidget {
  const EquipmentDetailScreen({super.key, required this.equipmentId});
  final String equipmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(equipmentDetailProvider(equipmentId));
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: BackButton(key: const Key('equipment-back'), onPressed: () => context.pop()),
        title: Text(l10n.eqDetailTitle, style: NalviumText.title),
      ),
      body: SafeArea(
        child: detail.when(
          skipLoadingOnReload: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Space.gutter),
              child: e is ApiHttpException && e.status == 404
                  ? _Gone(onBack: () => context.pop())
                  : ErrorPanel(error: e, onRetry: () => ref.invalidate(equipmentDetailProvider(equipmentId))),
            ),
          ),
          data: (d) => _Body(detail: d),
        ),
      ),
    );
  }
}

class _Gone extends StatelessWidget {
  const _Gone({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.eqGone, key: const Key('equipment-gone'), style: NalviumText.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: Space.x6),
        PrimaryButton(key: const Key('equipment-gone-back'), label: l10n.eqBackToHouse, onPressed: onBack),
      ],
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.detail});
  final EquipmentDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final e = detail.summary;
    final room = RoomCatalog.of(e.roomType);
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.x2, Space.gutter, Space.x10),
      children: [
        if (e.photoMediaId != null)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Corner.large),
              child: AuthedImage(key: const Key('equipment-photo'), mediaId: e.photoMediaId!, semanticLabel: l10n.photoSemantics),
            ),
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: EquipmentAvatar(kind: e.kind, size: 84, radius: 24),
          ),
        const SizedBox(height: Space.x5),
        Semantics(
          header: true,
          child: Text(e.displayName, key: const Key('equipment-name'), style: NalviumText.titleLarge.copyWith(fontSize: 28)),
        ),
        const SizedBox(height: Space.x1),
        // Marque et référence sont deux informations distinctes.
        if (e.brand != null)
          Text(e.brand!, key: const Key('equipment-brand'), style: NalviumText.bodyLarge.copyWith(color: NalviumColors.textSecondary))
        else
          Text(l10n.eqNoBrand, key: const Key('equipment-no-brand'), style: NalviumText.body.copyWith(color: NalviumColors.textMuted)),
        if (e.model != null)
          Text('${l10n.eqRefLabel} : ${e.model!}', key: const Key('equipment-model'), style: NalviumText.body.copyWith(color: NalviumColors.textSecondary))
        else ...[
          Text(l10n.eqRefNone, key: const Key('equipment-no-model'), style: NalviumText.body.copyWith(color: NalviumColors.textMuted)),
          const ReferenceHelpLink(),
        ],
        if (e.roomName != null) ...[
          const SizedBox(height: Space.x3),
          Align(
            alignment: Alignment.centerLeft,
            child: InfoPill(icon: room?.icon ?? Icons.meeting_room_outlined, label: e.roomName!),
          ),
        ],
        const SizedBox(height: Space.x6),
        PrimaryButton(
          key: const Key('equipment-diagnose'),
          label: l10n.eqDiagnose,
          icon: Icons.build_circle_outlined,
          onPressed: () => showDiagnoseSheet(context, ref, e.id),
        ),
        const SizedBox(height: Space.x8),
        Semantics(
          header: true,
          child: Text(l10n.eqProblems, style: NalviumText.title.copyWith(fontSize: 19)),
        ),
        const SizedBox(height: Space.x3),
        if (detail.diagnostics.isEmpty)
          Text(l10n.eqNoProblems, key: const Key('equipment-no-problems'), style: NalviumText.body)
        else
          for (final d in detail.diagnostics) _DiagnosticRow(d: d),
        const SizedBox(height: Space.x6),
        ManualSection(equipment: e, manual: detail.manual),
        const SizedBox(height: Space.x6),
        SecondaryButton(
          key: const Key('equipment-edit'),
          label: l10n.eqEdit,
          icon: Icons.edit_outlined,
          onPressed: () => context.push('/equipment/${e.id}/edit', extra: e),
        ),
        const SizedBox(height: Space.x1),
        TertiaryButton(
          key: const Key('equipment-delete'),
          label: l10n.eqDelete,
          color: NalviumColors.dangerText,
          onPressed: () => _confirmDelete(context, ref, e),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, EquipmentSummary e) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: NalviumColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Corner.large))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.gutter, Space.x6, Space.gutter, Space.x6),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.eqDeleteTitle, key: const Key('delete-title'), style: NalviumText.titleLarge),
              const SizedBox(height: Space.x3),
              Text(l10n.eqDeleteBody, key: const Key('delete-body'), style: NalviumText.body),
              const SizedBox(height: Space.x6),
              DangerButton(key: const Key('delete-confirm'), label: l10n.eqDeleteConfirm, onPressed: () => Navigator.of(context).pop(true)),
              const SizedBox(height: Space.x2),
              SecondaryButton(key: const Key('delete-cancel'), label: l10n.cancel, onPressed: () => Navigator.of(context).pop(false)),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(homeRepositoryProvider).deleteEquipment(e.id);
    } on ApiHttpException catch (err) {
      if (err.status != 404) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.eqDeleteFail)));
        return;
      } // déjà supprimé ailleurs : le résultat voulu est atteint
    } on ApiException {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.eqDeleteFail)));
      return;
    }
    ref.read(homeRevisionProvider.notifier).bump();
    ref.read(sessionsRevisionProvider.notifier).bump();
    if (context.mounted) context.pop();
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({required this.d});
  final EquipmentDiagnostic d;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = switch (d.status) {
      'resolved' => NalviumColors.success,
      'stopped' => NalviumColors.dangerText,
      'referred' => NalviumColors.textSecondary,
      _ => NalviumColors.primaryText,
    };
    final label = switch (d.status) {
      'resolved' => l10n.statusResolved,
      'stopped' => l10n.statusStopped,
      'referred' => l10n.statusReferred,
      _ => l10n.statusActive,
    };
    final title = (d.title ?? '').isEmpty ? l10n.untitledProblem : d.title!;
    return Semantics(
      button: true,
      child: InkWell(
        key: Key('equipment-diag-${d.id}'),
        borderRadius: BorderRadius.circular(Corner.medium),
        onTap: () => context.push(d.status == 'active' ? '/session/${d.id}' : '/session/${d.id}/summary'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.x3),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: NalviumText.title.copyWith(fontSize: 17.5)),
                    Row(
                      children: [
                        Icon(sessionIcon(d.status), size: 16, color: color),
                        const SizedBox(width: 5),
                        Flexible(child: Text(label, style: NalviumText.caption.copyWith(color: color, fontWeight: FontWeight.w700))),
                      ],
                    ),
                    Text(
                      relativeDate(l10n, d.updatedAt),
                      style: NalviumText.caption.copyWith(color: NalviumColors.textMuted, fontSize: 13),
                    ),
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

/// Lancer un diagnostic depuis l'équipement : la session sera liée à cet équipement dès sa création.
/// Même parcours que l'accueil (photo, description, vidéo), donc mêmes règles publicitaires (avant la session).
Future<void> showDiagnoseSheet(BuildContext context, WidgetRef ref, String equipmentId) async {
  final l10n = AppLocalizations.of(context);
  final choice = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: NalviumColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Corner.large))),
    builder: (sheet) => Padding(
      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.x6, Space.gutter, Space.x6),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.eqDiagnoseHow, key: const Key('diagnose-sheet-title'), style: NalviumText.titleLarge),
            const SizedBox(height: Space.x5),
            ChoiceTile(key: const Key('diagnose-photo'), label: l10n.takeAPhoto, icon: Icons.photo_camera_outlined, onTap: () => Navigator.of(sheet).pop('photo')),
            const SizedBox(height: Space.x3),
            ChoiceTile(key: const Key('diagnose-describe'), label: l10n.describeProblem, icon: Icons.edit_note_rounded, onTap: () => Navigator.of(sheet).pop('describe')),
            const SizedBox(height: Space.x3),
            ChoiceTile(key: const Key('diagnose-film'), label: l10n.filmShort, icon: Icons.videocam_outlined, onTap: () => Navigator.of(sheet).pop('film')),
          ],
        ),
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  switch (choice) {
    case 'photo':
      await startPhotoCapture(context, ref, equipmentId: equipmentId);
    case 'describe':
      context.push('/describe?equipment=$equipmentId');
    case 'film':
      context.push('/video/capture?equipment=$equipmentId');
  }
}
