import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/buttons.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import 'analysis_screen.dart';
import 'capture_flow.dart';

/// Aperçu : la photo occupe l'espace, la validation se fait dans une zone claire en bas.
/// Aucune analyse n'est lancée avant « Utiliser cette photo ».
class PhotoPreviewScreen extends ConsumerStatefulWidget {
  const PhotoPreviewScreen({super.key, required this.photoPath});
  final String photoPath;

  @override
  ConsumerState<PhotoPreviewScreen> createState() => _PhotoPreviewScreenState();
}

class _PhotoPreviewScreenState extends ConsumerState<PhotoPreviewScreen> {
  late String _path = widget.photoPath;

  bool _starting = false;

  /// Nouveau diagnostic : interstitiel éventuel (à partir du n°2), puis l'analyse démarre.
  Future<void> _use() async {
    if (_starting) return;
    setState(() => _starting = true);
    await ref.read(adsServiceProvider).beforeNewDiagnostic();
    if (!mounted) return;
    context.pushReplacement('/analyze', extra: PhotoStart(_path));
  }

  Future<void> _retake() async {
    final photo = await capturePhoto(context, ref);
    if (photo != null && mounted) setState(() => _path = photo.path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Fond marine : icônes de la barre d'état claires.
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: NalviumColors.textPrimary,
        body: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 200),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(_path),
                            key: const Key('preview-image'),
                            fit: BoxFit.contain,
                            semanticLabel: l10n.previewSemantics,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                          SafeArea(
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(Space.x3),
                                child: Material(
                                  color: Colors.black.withValues(alpha: 0.38),
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    key: const Key('close-preview'),
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                    ),
                                    tooltip: l10n.close,
                                    constraints: const BoxConstraints(
                                      minWidth: 48,
                                      minHeight: 48,
                                    ),
                                    onPressed: () => context.pop(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      Space.gutter,
                      Space.x6,
                      Space.gutter,
                      Space.x4 + MediaQuery.paddingOf(context).bottom,
                    ),
                    decoration: const BoxDecoration(
                      color: NalviumColors.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(Corner.large),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l10n.previewSharp, style: NalviumText.title),
                        const SizedBox(height: Space.x1),
                        Text(
                          l10n.previewTip,
                          style: NalviumText.body.copyWith(fontSize: 15),
                        ),
                        const SizedBox(height: Space.x5),
                        PrimaryButton(
                          key: const Key('use-photo'),
                          label: l10n.usePhoto,
                          loading: _starting,
                          onPressed: _use,
                        ),
                        const SizedBox(height: Space.x2),
                        SecondaryButton(
                          key: const Key('retake-photo'),
                          label: l10n.retake,
                          icon: Icons.replay_rounded,
                          onPressed: _retake,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
