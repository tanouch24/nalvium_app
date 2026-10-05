import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/nalvium_colors.dart';
import '../theme/nalvium_spacing.dart';
import '../theme/nalvium_typography.dart';

enum _Kind { primary, secondary, danger }

/// Bouton plein : l'action principale d'un écran (une seule par écran).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.haptic = true,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool haptic;

  @override
  Widget build(BuildContext context) => _Button(
    kind: _Kind.primary,
    label: label,
    onPressed: onPressed,
    icon: icon,
    loading: loading,
    haptic: haptic,
  );
}

/// Bouton cerclé : réponse ou action secondaire.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => _Button(
    kind: _Kind.secondary,
    label: label,
    onPressed: onPressed,
    icon: icon,
  );
}

/// Réservé aux écrans de sécurité.
class DangerButton extends StatelessWidget {
  const DangerButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) =>
      _Button(kind: _Kind.danger, label: label, onPressed: onPressed);
}

/// Action discrète (lien).
class TertiaryButton extends StatelessWidget {
  const TertiaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = NalviumColors.primary,
  });
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 48),
    child: TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        disabledForegroundColor: NalviumColors.textMuted,
        padding: const EdgeInsets.symmetric(
          horizontal: Space.x4,
          vertical: Space.x3,
        ),
        textStyle: NalviumText.button.copyWith(fontSize: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Corner.medium),
        ),
      ),
      child: Text(label, textAlign: TextAlign.center),
    ),
  );
}

class _Button extends StatelessWidget {
  const _Button({
    required this.kind,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.haptic = false,
  });
  final _Kind kind;
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool haptic;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final filled = kind != _Kind.secondary;
    final bg = switch (kind) {
      _Kind.primary => NalviumColors.primary,
      _Kind.danger => NalviumColors.danger,
      _Kind.secondary => NalviumColors.surface,
    };
    final pressed = switch (kind) {
      _Kind.primary => NalviumColors.primaryPressed,
      _Kind.danger => NalviumColors.dangerPressed,
      _Kind.secondary => NalviumColors.surfaceSubtle,
    };
    final fg = filled ? Colors.white : NalviumColors.textPrimary;

    return Semantics(
      button: true,
      enabled: enabled,
      label: loading ? label : null, // pendant le chargement, le texte est remplacé par un indicateur
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Space.tap),
        child: Material(
          color: enabled
              ? bg
              : (filled ? NalviumColors.surfaceSubtle : NalviumColors.surface),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Corner.medium),
            side: filled
                ? BorderSide.none
                : BorderSide(
                    color: enabled
                        ? NalviumColors.borderSubtle
                        : NalviumColors.surfaceSubtle,
                    width: 1.5,
                  ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled
                ? () {
                    if (haptic) HapticFeedback.lightImpact();
                    onPressed!();
                  }
                : null,
            overlayColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.pressed)
                  ? pressed.withValues(alpha: filled ? 1 : 0.9)
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Space.x5,
                vertical: Space.x4,
              ),
              child: Center(
                child: loading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: fg,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(
                              icon,
                              size: 22,
                              color: enabled ? fg : NalviumColors.textMuted,
                            ),
                            const SizedBox(width: Space.x2),
                          ],
                          Flexible(
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: NalviumText.button.copyWith(
                                color: enabled ? fg : NalviumColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
