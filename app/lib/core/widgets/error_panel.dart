import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../domain/video.dart';
import '../network/api_exceptions.dart';
import '../theme/nalvium_colors.dart';
import '../theme/nalvium_spacing.dart';
import '../theme/nalvium_typography.dart';
import 'buttons.dart';

/// Erreur honnête selon son type : ce qui s'est passé, puis quoi faire. Jamais de faux résultat.
class ErrorPanel extends StatelessWidget {
  const ErrorPanel({
    super.key,
    required this.error,
    required this.onRetry,
    this.secondary,
  });
  final Object error;
  final VoidCallback? onRetry;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (IconData icon, String title, String body) = switch (error) {
      ApiNotConfigured() => (
        Icons.settings_suggest_outlined,
        l10n.errNotConfiguredTitle,
        l10n.errNotConfiguredBody,
      ),
      ApiNetworkException() => (
        Icons.wifi_off_rounded,
        l10n.errNetworkTitle,
        l10n.errNetworkBody,
      ),
      ApiTimeoutException() => (
        Icons.timer_off_outlined,
        l10n.errTimeoutTitle,
        l10n.errTimeoutBody,
      ),
      VideoException(failure: VideoFailure.cameraDenied) => (Icons.videocam_off_outlined, l10n.errCameraDeniedTitle, l10n.errCameraDeniedBody),
      VideoException(failure: VideoFailure.cameraUnavailable) => (Icons.videocam_off_outlined, l10n.errCameraUnavailableTitle, l10n.errCameraUnavailableBody),
      VideoException(failure: VideoFailure.tooShort) => (Icons.timer_outlined, l10n.errVideoTooShortTitle, l10n.errVideoTooShortBody),
      VideoException(failure: VideoFailure.tooLarge) => (Icons.sd_storage_outlined, l10n.errVideoTooLargeTitle, l10n.errVideoTooLargeBody),
      ApiHttpException(code: 'video_too_long') => (Icons.timer_off_outlined, l10n.errVideoTooLongTitle, l10n.errVideoTooLongBody),
      ApiHttpException(code: 'file_too_large') => (Icons.sd_storage_outlined, l10n.errVideoTooLargeTitle, l10n.errVideoTooLargeBody),
      ApiHttpException(code: 'invalid_video') => (Icons.video_file_outlined, l10n.errVideoInvalidTitle, l10n.errVideoInvalidBody),
      ApiHttpException(isAnalysisUnavailable: true) => (
        Icons.hourglass_empty_rounded,
        l10n.errUnavailableTitle,
        l10n.errUnavailableBody,
      ),
      _ => (
        Icons.error_outline_rounded,
        l10n.errGenericTitle,
        l10n.errGenericBody,
      ),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: NalviumColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 38, color: NalviumColors.primary),
          ),
        ),
        const SizedBox(height: Space.x6),
        Text(
          title,
          style: NalviumText.titleLarge,
          textAlign: TextAlign.center,
          key: const Key('error-title'),
        ),
        const SizedBox(height: Space.x2),
        Text(body, style: NalviumText.body, textAlign: TextAlign.center),
        const SizedBox(height: Space.x6),
        if (onRetry != null)
          PrimaryButton(
            key: const Key('retry'),
            label: l10n.retry,
            onPressed: onRetry,
          ),
        if (secondary != null) ...[
          const SizedBox(height: Space.x2),
          secondary!,
        ],
      ],
    );
  }
}
