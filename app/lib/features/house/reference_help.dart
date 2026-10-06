import 'package:flutter/material.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/buttons.dart';
import '../../l10n/app_localizations.dart';

/// Lien discret « Où trouver la référence ? » : aide courte, jamais bloquante.
class ReferenceHelpLink extends StatelessWidget {
  const ReferenceHelpLink({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        key: const Key('reference-help'),
        onPressed: () => showModalBottomSheet<void>(
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
                  Text(l10n.eqRefHelpTitle, style: NalviumText.titleLarge),
                  const SizedBox(height: Space.x3),
                  Text(l10n.eqRefHelpBody, key: const Key('reference-help-body'), style: NalviumText.body),
                  const SizedBox(height: Space.x6),
                  PrimaryButton(label: l10n.eqRefHelpClose, onPressed: () => Navigator.of(sheet).pop()),
                ],
              ),
            ),
          ),
        ),
        icon: const Icon(Icons.help_outline_rounded, size: 18),
        label: Text(l10n.eqRefWhere),
        style: TextButton.styleFrom(
          foregroundColor: NalviumColors.primaryText,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: Space.x2),
          textStyle: NalviumText.button.copyWith(fontSize: 15),
        ),
      ),
    );
  }
}
