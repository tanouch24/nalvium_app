import 'package:flutter/material.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/authed_image.dart';
import '../../core/widgets/choice_tile.dart';
import '../../domain/equipment.dart';

/// Visuel d'un équipement : sa vraie photo si elle existe, sinon un pictogramme (jamais de photo fictive).
class EquipmentAvatar extends StatelessWidget {
  const EquipmentAvatar({super.key, required this.kind, this.mediaId, this.size = 56, this.radius = 16});
  final EquipmentKind kind;
  final String? mediaId;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: mediaId == null
            ? ColoredBox(
                color: NalviumColors.primarySoft,
                child: Icon(kind.icon, color: NalviumColors.primary, size: size * 0.48),
              )
            : AuthedImage(mediaId: mediaId!),
      ),
    ),
  );
}

/// Grille de choix à deux colonnes qui s'adapte au zoom du texte (pas de hauteur fixe → pas d'overflow).
class TwoColumnWrap extends StatelessWidget {
  const TwoColumnWrap({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      const gap = Space.x3;
      final w = (c.maxWidth - gap) / 2;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final child in children) SizedBox(width: w, child: child)],
      );
    },
  );
}

class KindTile extends StatelessWidget {
  const KindTile({super.key, required this.kind, required this.onTap, this.selected = false});
  final EquipmentKind kind;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: ChoiceTile(key: Key('kind-${kind.slug}'), label: kind.label, icon: kind.icon, vertical: true, refined: true, onTap: onTap),
  );
}

class RoomTile extends StatelessWidget {
  const RoomTile({super.key, required this.room, required this.onTap});
  final RoomKind room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      ChoiceTile(key: Key('room-${room.slug}'), label: room.label, icon: room.icon, vertical: true, refined: true, onTap: onTap);
}

/// Petite pastille d'information : icône + texte (jamais la couleur seule).
class InfoPill extends StatelessWidget {
  const InfoPill({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Space.x3, vertical: Space.x1 + 1),
    decoration: BoxDecoration(color: NalviumColors.surfaceSubtle, borderRadius: BorderRadius.circular(Corner.small)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: NalviumColors.textSecondary),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: NalviumText.caption.copyWith(fontWeight: FontWeight.w600))),
      ],
    ),
  );
}

/// « Bosch · SMS46 » : la marque et le modèle connus, rien d'inventé.
String? brandModel(String? brand, String? model) {
  final parts = [?brand, ?model];
  return parts.isEmpty ? null : parts.join(' · ');
}
