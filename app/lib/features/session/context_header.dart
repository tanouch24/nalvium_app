import 'package:flutter/material.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/authed_image.dart';
import '../../core/widgets/viewfinder.dart';
import '../../l10n/app_localizations.dart';

/// Contexte constant du diagnostic : « on parle toujours de CET objet ».
/// Même vignette (64 dp, rayon 16, coins de viseur discrets) sur tous les écrans de guidage.
class ContextHeader extends StatelessWidget {
  const ContextHeader({
    super.key,
    this.mediaId,
    this.title,
    this.category,
    this.isVideo = false,
  });
  final String? mediaId;
  final String? title;
  final String? category;

  /// La vignette est une image extraite d'une vidéo : petit badge de lecture.
  final bool isVideo;

  static const thumb = 64.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasTitle = title != null && title!.trim().isNotEmpty;
    if (mediaId == null && !hasTitle) return const SizedBox.shrink();
    return Row(
      children: [
        SizedBox(
          width: thumb,
          height: thumb,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: mediaId == null
                    ? const ColoredBox(
                        color: NalviumColors.primarySoft,
                        child: Icon(
                          Icons.edit_note_rounded,
                          color: NalviumColors.primary,
                          size: 30,
                        ),
                      )
                    : AuthedImage(
                        mediaId: mediaId!,
                        semanticLabel: isVideo
                            ? l10n.videoSemantics
                            : l10n.photoSemantics,
                      ),
              ),
              if (isVideo)
                const Center(
                  child: DecoratedBox(
                    key: Key('video-badge'),
                    decoration: BoxDecoration(
                      color: Color(0x8C000000),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              if (mediaId != null)
                ViewfinderCorners(
                  color: Colors.white.withValues(alpha: 0.85),
                  length: 9,
                  stroke: 2,
                  radius: 4,
                  inset: 5,
                ),
            ],
          ),
        ),
        const SizedBox(width: Space.x4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasTitle)
                Text(
                  title!,
                  key: const Key('context-title'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: NalviumText.title.copyWith(fontSize: 18),
                ),
              if (category != null && category!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    category!,
                    key: const Key('category-label'),
                    style: NalviumText.caption,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
