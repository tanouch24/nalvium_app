import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/widgets/buttons.dart';
import '../../l10n/app_localizations.dart';
import '../capture/capture_flow.dart';

/// Sorties de secours quand la vidéo n'est pas possible : une photo, une description, ou l'accueil.
class VideoAlternatives extends ConsumerWidget {
  const VideoAlternatives({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TertiaryButton(
          key: const Key('alt-photo'),
          label: l10n.takeAPhoto,
          onPressed: () => startPhotoCapture(context, ref),
        ),
        TertiaryButton(
          key: const Key('alt-describe'),
          label: l10n.describeProblem,
          onPressed: () => context.go('/describe'),
        ),
        TertiaryButton(
          key: const Key('back-home'),
          label: l10n.backToHome,
          color: NalviumColors.textSecondary,
          onPressed: () => context.go('/home'),
        ),
      ],
    );
  }
}
