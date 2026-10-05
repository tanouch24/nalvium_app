import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/providers.dart';
import '../theme/nalvium_colors.dart';

/// Affiche une photo PRIVÉE du backend (en-tête d'identité requis). Placeholder si indisponible.
class AuthedImage extends ConsumerWidget {
  const AuthedImage({
    super.key,
    required this.mediaId,
    this.fit = BoxFit.cover,
    this.semanticLabel,
  });
  final String mediaId;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(mediaImageSourceProvider(mediaId)).value;
    const placeholder = ColoredBox(
      color: NalviumColors.surfaceSubtle,
      child: Center(
        child: Icon(Icons.image_outlined, color: NalviumColors.textMuted),
      ),
    );
    if (source == null) return placeholder;
    return Image.network(
      source.url,
      headers: source.headers,
      fit: fit,
      semanticLabel: semanticLabel,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : placeholder,
    );
  }
}
