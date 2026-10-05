import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../l10n/app_localizations.dart';
import 'analysis_screen.dart';
import 'capture_flow.dart';

class PhotoPreviewScreen extends ConsumerStatefulWidget {
  const PhotoPreviewScreen({super.key, required this.photoPath});
  final String photoPath;

  @override
  ConsumerState<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends ConsumerState<PhotoPreviewScreen> {
  late String _path = widget.photoPath;

  Future<void> _retake() async {
    final photo = await capturePhoto(context, ref);
    if (photo != null && mounted) setState(() => _path = photo.path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.close,
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.previewTitle, style: theme.textTheme.titleLarge),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(NalviumSpacing.lg, NalviumSpacing.sm, NalviumSpacing.lg, NalviumSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(NalviumSpacing.radius),
                  child: ColoredBox(
                    color: NalviumColors.greyLight,
                    child: Image.file(
                      File(_path),
                      key: const Key('preview-image'),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Center(child: Icon(Icons.broken_image_outlined, size: 48, color: NalviumColors.grey)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: NalviumSpacing.md),
              Text(l10n.previewQuestion, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: NalviumSpacing.md),
              FilledButton(
                key: const Key('use-photo'),
                onPressed: () => context.pushReplacement('/analyze', extra: PhotoStart(_path)),
                child: Text(l10n.usePhoto),
              ),
              const SizedBox(height: NalviumSpacing.sm),
              OutlinedButton(
                key: const Key('retake-photo'),
                onPressed: _retake,
                child: Text(l10n.retake),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
