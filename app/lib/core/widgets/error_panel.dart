import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../network/api_exceptions.dart';
import '../theme/nalvium_colors.dart';
import '../theme/nalvium_spacing.dart';

/// Message d'erreur honnête selon le type d'erreur, avec Réessayer.
class ErrorPanel extends StatelessWidget {
  const ErrorPanel({super.key, required this.error, required this.onRetry, this.secondary});
  final Object error;
  final VoidCallback? onRetry;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final (IconData icon, String title, String body) = switch (error) {
      ApiNotConfigured() => (Icons.settings_suggest_outlined, l10n.errNotConfiguredTitle, l10n.errNotConfiguredBody),
      ApiNetworkException() => (Icons.wifi_off_rounded, l10n.errNetworkTitle, l10n.errNetworkBody),
      ApiTimeoutException() => (Icons.timer_off_outlined, l10n.errTimeoutTitle, l10n.errTimeoutBody),
      ApiHttpException(isAnalysisUnavailable: true) => (Icons.hourglass_empty_rounded, l10n.errUnavailableTitle, l10n.errUnavailableBody),
      _ => (Icons.error_outline_rounded, l10n.errGenericTitle, l10n.errGenericBody),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(color: NalviumColors.blueSoft, shape: BoxShape.circle),
          child: Icon(icon, size: 36, color: NalviumColors.blue),
        ),
        const SizedBox(height: NalviumSpacing.lg),
        Text(title, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center, key: const Key('error-title')),
        const SizedBox(height: NalviumSpacing.sm),
        Text(body, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: NalviumSpacing.lg),
        if (onRetry != null)
          FilledButton(key: const Key('retry'), onPressed: onRetry, child: Text(l10n.retry)),
        if (secondary != null) ...[const SizedBox(height: NalviumSpacing.sm), secondary!],
      ],
    );
  }
}
