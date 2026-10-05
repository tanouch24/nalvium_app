import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/providers.dart';
import '../theme/nalvium_colors.dart';

/// Affiche une photo PRIVÉE du backend (en-tête d'identité requis). Placeholder si indisponible.
class AuthedImage extends ConsumerWidget {
  const AuthedImage({super.key, required this.mediaId, this.fit = BoxFit.cover});
  final String mediaId;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(mediaImageSourceProvider(mediaId)).value;
    const placeholder = ColoredBox(
      color: NalviumColors.greyLight,
      child: Center(child: Icon(Icons.image_outlined, color: NalviumColors.grey)),
    );
    if (source == null) return placeholder;
    return Image.network(
      source.url,
      headers: source.headers,
      fit: fit,
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (_, child, progress) => progress == null ? child : placeholder,
    );
  }
}
