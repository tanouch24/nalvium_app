import 'package:flutter/material.dart';

import '../theme/nalvium_colors.dart';
import '../theme/nalvium_spacing.dart';
import '../theme/nalvium_typography.dart';

enum StatusTone { info, success, danger, neutral }

/// Statut = icône + texte (jamais la couleur seule).
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
  });
  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (Color fg, Color bg, IconData defaultIcon) = switch (tone) {
      StatusTone.info => (
        NalviumColors.primaryText,
        NalviumColors.primarySoft,
        Icons.schedule_rounded,
      ),
      StatusTone.success => (
        NalviumColors.success,
        NalviumColors.successSoft,
        Icons.check_circle_rounded,
      ),
      StatusTone.danger => (
        NalviumColors.dangerText,
        NalviumColors.dangerSoft,
        Icons.warning_amber_rounded,
      ),
      StatusTone.neutral => (
        NalviumColors.textSecondary,
        NalviumColors.surfaceSubtle,
        Icons.engineering_rounded,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.x3,
        vertical: Space.x1 + 1,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Corner.small),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? defaultIcon, size: 15, color: fg),
          const SizedBox(width: Space.x1 + 2),
          Flexible(
            child: Text(
              label,
              style: NalviumText.caption.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
