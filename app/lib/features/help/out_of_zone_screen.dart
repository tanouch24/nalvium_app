import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/buttons.dart';
import '../../l10n/app_localizations.dart';

class OutOfZoneArgs {
  const OutOfZoneArgs({required this.areaName, required this.radiusKm, this.fromSession = false, this.safety = false});
  final String areaName;
  final int radiusKm;

  /// Vient d'un diagnostic : « Continuer avec Nalvium » ramène à ce diagnostic, resté intact.
  final bool fromSession;

  /// Le diagnostic est un arrêt de sécurité : la sécurité reste prioritaire, aucune fausse intervention.
  final bool safety;
}

/// Hors zone : aucune demande n'est envoyée. Ton honnête, sans date ni promesse ; Nalvium reste utilisable.
class OutOfZoneScreen extends StatelessWidget {
  const OutOfZoneScreen({super.key, required this.args});
  final OutOfZoneArgs args;

  void _continue(BuildContext context) {
    if (args.fromSession) {
      context.pop(); // cet écran
      if (context.canPop()) context.pop(); // le formulaire : retour au diagnostic intact
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Space.gutter, Space.x10, Space.gutter, Space.x8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(color: NalviumColors.primarySoft, shape: BoxShape.circle),
                child: const Icon(Icons.place_outlined, size: 44, color: NalviumColors.primary),
              ),
            ),
            const SizedBox(height: Space.x6),
            Semantics(
              header: true,
              child: Text(l10n.oozTitle, key: const Key('ooz-title'), textAlign: TextAlign.center, style: NalviumText.titleLarge),
            ),
            const SizedBox(height: Space.x3),
            if (args.safety) ...[
              Text(l10n.oozSafety, key: const Key('ooz-safety'), textAlign: TextAlign.center, style: NalviumText.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: Space.x2),
              Text(l10n.helpEmergency, key: const Key('ooz-emergency'), textAlign: TextAlign.center, style: NalviumText.caption.copyWith(color: NalviumColors.dangerText, fontWeight: FontWeight.w600)),
              const SizedBox(height: Space.x3),
            ],
            Text(l10n.oozBody(args.areaName, args.radiusKm), key: const Key('ooz-body'), textAlign: TextAlign.center, style: NalviumText.body),
            const SizedBox(height: Space.x8),
            PrimaryButton(key: const Key('ooz-continue'), label: l10n.oozContinue, onPressed: () => _continue(context)),
            const SizedBox(height: Space.x1),
            TertiaryButton(key: const Key('ooz-back'), label: l10n.oozBack, color: NalviumColors.textSecondary, onPressed: () => context.pop()),
          ]),
        ),
      ),
    );
  }
}
