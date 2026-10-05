import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/nalvium_colors.dart';
import '../theme/nalvium_spacing.dart';
import '../theme/nalvium_typography.dart';
import 'motion.dart';

/// Grande réponse tactile (Oui / Non / …) : un choix neutre, pas une action principale.
/// État pressé : léger rétrécissement + bordure et fond bleus doux.
class ChoiceTile extends StatefulWidget {
  const ChoiceTile({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.vertical = false,
  });
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  /// Icône au-dessus du libellé (grille de résultats) plutôt qu'à gauche.
  final bool vertical;

  @override
  State<ChoiceTile> createState() => _ChoiceTileState();
}

class _ChoiceTileState extends State<ChoiceTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final d = motionDuration(context, const Duration(milliseconds: 110));
    final label = Text(
      widget.label,
      textAlign: widget.vertical ? TextAlign.center : TextAlign.start,
      style: NalviumText.button.copyWith(
        fontSize: 17.5,
        color: NalviumColors.textPrimary,
      ),
    );
    final Widget content = widget.vertical
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 28, color: NalviumColors.primary),
                const SizedBox(height: Space.x2),
              ],
              label,
            ],
          )
        : Row(
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 24, color: NalviumColors.primary),
                const SizedBox(width: Space.x3),
              ],
              Expanded(child: label),
            ],
          );

    return Semantics(
      button: true,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: d,
        child: AnimatedContainer(
          duration: d,
          constraints: BoxConstraints(minHeight: widget.vertical ? 92 : 62),
          decoration: BoxDecoration(
            color: _pressed ? NalviumColors.primarySoft : NalviumColors.surface,
            borderRadius: BorderRadius.circular(Corner.medium),
            border: Border.all(
              color: _pressed
                  ? NalviumColors.primary
                  : NalviumColors.borderSubtle,
              width: 1.5,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: BorderRadius.circular(Corner.medium),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onHighlightChanged: (v) => setState(() => _pressed = v),
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onTap();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.x5,
                  vertical: Space.x4,
                ),
                child: Align(
                  alignment: widget.vertical
                      ? Alignment.center
                      : Alignment.centerLeft,
                  widthFactor: 1,
                  heightFactor: 1,
                  child: content,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
