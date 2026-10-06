import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/error_panel.dart';
import '../../domain/equipment.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import 'house_widgets.dart';

/// Maison : la mémoire des équipements du logement, rangés par pièce. Aucun appel IA, aucune publicité,
/// aucune statistique : simple, visuel, calme.
class HouseScreen extends ConsumerWidget {
  const HouseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final home = ref.watch(homeProvider);
    final hasItems = home.value?.equipment.isNotEmpty ?? false;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: Space.gutter,
        title: Text(l10n.houseEmptyTitle, key: const Key('house-title'), style: NalviumText.titleLarge),
        toolbarHeight: 72,
        actions: [
          if (hasItems)
            Padding(
              padding: const EdgeInsets.only(right: Space.x2),
              child: IconButton(
                key: const Key('house-add-icon'),
                tooltip: l10n.houseAdd,
                icon: const Icon(Icons.add_rounded),
                iconSize: 28,
                color: NalviumColors.primary,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () => context.push('/equipment/add'),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: home.when(
          // On garde l'ancienne liste affichée pendant un rechargement : pas de clignotement.
          skipLoadingOnReload: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Space.gutter),
              child: ErrorPanel(error: e, onRetry: () => ref.invalidate(homeProvider)),
            ),
          ),
          data: (data) => data.equipment.isEmpty
              ? const _EmptyHouse()
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(homeProvider);
                    await ref.read(homeProvider.future);
                  },
                  child: _Filled(data: data),
                ),
        ),
      ),
    );
  }
}

class _EmptyHouse extends StatelessWidget {
  const _EmptyHouse();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Align(
      // Centre optique : un peu au-dessus du milieu, pour que l'état vide ait une intention et pas un grand blanc.
      alignment: const Alignment(0, -0.3),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.gutter, Space.x6, Space.gutter, Space.x10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(color: NalviumColors.primarySoft, shape: BoxShape.circle),
                child: const Icon(Icons.house_outlined, size: 38, color: NalviumColors.primary),
              ),
            ),
            const SizedBox(height: Space.x5),
            Text(
              l10n.houseEmptyBody,
              key: const Key('house-empty-body'),
              style: NalviumText.title.copyWith(fontSize: 21, height: 1.35),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.x3),
            Text(l10n.houseEmptyHint, style: NalviumText.body.copyWith(height: 1.45), textAlign: TextAlign.center),
            const SizedBox(height: Space.x6),
            PrimaryButton(
              key: const Key('house-add'),
              label: l10n.houseAdd,
              icon: Icons.add_rounded,
              onPressed: () => context.push('/equipment/add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Filled extends StatelessWidget {
  const _Filled({required this.data});
  final HomeData data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final groups = data.byRoom();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(Space.gutter, Space.x1, Space.gutter, Space.x10),
      children: [
        for (final g in groups) ...[
          Padding(
            padding: const EdgeInsets.only(top: Space.x6, bottom: Space.x2 + 2),
            child: Semantics(
              header: true,
              child: Row(
                children: [
                  Icon(
                    RoomCatalog.of(g.value.first.roomType)?.icon ?? Icons.meeting_room_outlined,
                    size: 20,
                    color: NalviumColors.textMuted,
                  ),
                  const SizedBox(width: Space.x2),
                  Flexible(
                    child: Text(
                      g.key ?? l10n.houseNoRoom,
                      style: NalviumText.title.copyWith(fontSize: 17, color: NalviumColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final e in g.value) EquipmentRow(equipment: e),
        ],
        const SizedBox(height: Space.x6),
        SecondaryButton(
          key: const Key('house-add'),
          label: l10n.houseAdd,
          icon: Icons.add_rounded,
          onPressed: () => context.push('/equipment/add'),
        ),
      ],
    );
  }
}

/// Ligne compacte : visuel, nom, marque, nombre de diagnostics. Une seule zone tactile.
class EquipmentRow extends StatelessWidget {
  const EquipmentRow({super.key, required this.equipment});
  final EquipmentSummary equipment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final e = equipment;
    final diag = e.diagnosticsCount == 0
        ? l10n.houseNoIssue
        : (e.diagnosticsCount == 1 ? l10n.houseDiagnosticsOne : l10n.eqDiagnosticsCount(e.diagnosticsCount));
    final brand = brandModel(e.brand, e.model) ?? l10n.eqNoBrand;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x2 + 2),
      child: Semantics(
        button: true,
        label: '${e.displayName}. $brand. $diag',
        excludeSemantics: true,
        child: Material(
          color: NalviumColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Corner.small + 4),
            side: const BorderSide(color: NalviumColors.borderSubtle),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: Key('equipment-${e.id}'),
            onTap: () => context.push('/equipment/${e.id}'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.x3, Space.x3 - 2, Space.x3, Space.x3 - 2),
              child: Row(
                children: [
                  EquipmentAvatar(kind: e.kind, mediaId: e.photoMediaId, size: 52, radius: 14),
                  const SizedBox(width: Space.x3 + 2),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.displayName, maxLines: 2, overflow: TextOverflow.ellipsis, style: NalviumText.title.copyWith(fontSize: 17.5, height: 1.25)),
                        Text(brand, maxLines: 1, overflow: TextOverflow.ellipsis, style: NalviumText.caption.copyWith(color: NalviumColors.textSecondary)),
                        Text(
                          diag,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
        ),
      ),
    );
  }
}
