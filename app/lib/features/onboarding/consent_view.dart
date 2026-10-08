import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/buttons.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';

/// Accord explicite AVANT tout envoi à l'IA (App Store 5.1.2(i)) : ce qui part, à qui, et les limites.
class ConsentView extends ConsumerWidget {
  const ConsentView({super.key, required this.onDone});

  /// Appelé après « J'accepte » (true) ou « Pas maintenant » (false).
  final void Function(bool accepted) onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    Widget item(String text) => Padding(
      padding: const EdgeInsets.only(bottom: Space.x2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 3),
            child: Icon(Icons.arrow_outward_rounded, size: 18, color: NalviumColors.primaryText),
          ),
          const SizedBox(width: Space.x3),
          Expanded(child: Text(text, style: NalviumText.body.copyWith(color: NalviumColors.textPrimary))),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.consentTitle, key: const Key('consent-title'), style: NalviumText.titleLarge.copyWith(fontSize: 29)),
        ),
        const SizedBox(height: Space.x4),
        Text(l10n.consentIntro, style: NalviumText.bodyLarge.copyWith(fontSize: 17)),
        const SizedBox(height: Space.x3),
        Container(
          padding: const EdgeInsets.fromLTRB(Space.x4, Space.x4, Space.x4, Space.x2),
          decoration: BoxDecoration(color: NalviumColors.surface, borderRadius: BorderRadius.circular(Corner.medium)),
          child: Column(children: [item(l10n.consentItem1), item(l10n.consentItem2), item(l10n.consentItem3)]),
        ),
        const SizedBox(height: Space.x4),
        Text(l10n.consentNoIdentity, style: NalviumText.body),
        const SizedBox(height: Space.x3),
        Text(l10n.consentLimits, style: NalviumText.body.copyWith(color: NalviumColors.textPrimary, fontWeight: FontWeight.w600)),
        Align(
          alignment: Alignment.centerLeft,
          child: TertiaryButton(
            key: const Key('consent-privacy'),
            label: l10n.consentPrivacy,
            color: NalviumColors.primaryText,
            onPressed: () => context.push('/settings/legal/privacy'),
          ),
        ),
        const SizedBox(height: Space.x4),
        PrimaryButton(
          key: const Key('consent-accept'),
          label: l10n.consentAccept,
          onPressed: () async {
            await ref.read(aiConsentProvider.notifier).give();
            onDone(true);
          },
        ),
        const SizedBox(height: Space.x1),
        TertiaryButton(
          key: const Key('consent-decline'),
          label: l10n.consentDecline,
          color: NalviumColors.textSecondary,
          onPressed: () => onDone(false),
        ),
      ],
    );
  }
}

/// Écran autonome : demandé quand un diagnostic commence sans accord (accord retiré ou démarrage passé).
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});
  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  @override
  void initState() {
    super.initState();
    // Un message précédent ne doit jamais masquer le bouton « J'accepte ».
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('consent-close'),
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.close,
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.x8),
          child: ConsentView(
            onDone: (accepted) {
              if (!accepted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(key: const Key('consent-required'), content: Text(l10n.consentRequiredBody)),
                );
              }
              context.go('/home');
            },
          ),
        ),
      ),
    );
  }
}
