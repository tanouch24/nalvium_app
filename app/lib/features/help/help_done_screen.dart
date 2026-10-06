import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/buttons.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import 'request_labels.dart';

/// Confirmation calme : aucun délai promis, aucun professionnel annoncé.
class HelpDoneScreen extends ConsumerWidget {
  const HelpDoneScreen({super.key, required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final req = ref.watch(requestProvider(requestId)).value;
    // Le retour normal mène à Dépannage (Vos demandes), jamais au diagnostic encore actif.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/repair');
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              Space.gutter,
              Space.x8,
              Space.gutter,
              Space.x8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      color: NalviumColors.successSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 44,
                      color: NalviumColors.success,
                    ),
                  ),
                ),
                const SizedBox(height: Space.x5),
                Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(
                    l10n.helpDoneTitle,
                    key: const Key('help-done-title'),
                    textAlign: TextAlign.center,
                    style: NalviumText.titleLarge.copyWith(fontSize: 25, height: 1.25),
                  ),
                ),
                const SizedBox(height: Space.x3),
                Text(
                  l10n.helpDoneBody,
                  key: const Key('help-done-body'),
                  textAlign: TextAlign.center,
                  style: NalviumText.body.copyWith(height: 1.5),
                ),
                if (req != null) ...[
                  const SizedBox(height: Space.x6),
                  Container(
                    key: const Key('help-done-summary'),
                    padding: const EdgeInsets.all(Space.x4),
                    decoration: BoxDecoration(
                      color: NalviumColors.surface,
                      borderRadius: BorderRadius.circular(Corner.small + 4),
                      border: Border.all(color: NalviumColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.summary ?? '',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: NalviumText.title.copyWith(fontSize: 17.5),
                        ),
                        const SizedBox(height: Space.x2),
                        Text(
                          [
                            ?req.city,
                            availabilityLabel(l10n, req),
                            if (req.mediaIds.isNotEmpty)
                              l10n.requestMediaCount(req.mediaIds.length),
                          ].join(' · '),
                          style: NalviumText.caption,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: Space.x6),
                PrimaryButton(
                  key: const Key('help-done-see'),
                  label: l10n.helpSeeRequest,
                  onPressed: () {
                    context.go('/repair');
                    context.push('/requests/$requestId');
                  },
                ),
                const SizedBox(height: Space.x1),
                TertiaryButton(
                  key: const Key('help-done-home'),
                  label: l10n.helpBackHome,
                  color: NalviumColors.textSecondary,
                  onPressed: () => context.go('/home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
