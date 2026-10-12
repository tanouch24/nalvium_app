import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/authed_image.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/motion.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import '../capture/capture_flow.dart';
import '../share/share_card.dart';

/// Charge et décode les deux photos de la carte « Avant / après » (avant : vignette privée du serveur,
/// après : fichier local). Appelé UNIQUEMENT après un appui explicite sur « Partager ». Surchargé en test.
typedef BeforeAfterLoader = Future<(ui.Image?, ui.Image?)> Function(String? beforeMediaId, String afterPath);

final beforeAfterImagesProvider = Provider<BeforeAfterLoader>(
  (ref) => (beforeMediaId, afterPath) async {
    Future<ui.Image?> decode(Uint8List? bytes) async {
      if (bytes == null || bytes.isEmpty) return null;
      try {
        final codec = await ui.instantiateImageCodec(bytes, targetWidth: 720);
        final frame = await codec.getNextFrame();
        codec.dispose();
        return frame.image;
      } catch (_) {
        return null;
      }
    }

    Uint8List? afterBytes;
    try {
      afterBytes = await File(afterPath).readAsBytes();
    } catch (_) {}
    Uint8List? beforeBytes;
    if (beforeMediaId != null) {
      try {
        final url = ref.read(apiConfigProvider).uri('/v1/media/$beforeMediaId/thumbnail');
        final headers = await ref.read(apiClientProvider).authHeaders();
        final res = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));
        if (res.statusCode == 200) beforeBytes = res.bodyBytes;
      } catch (_) {}
    }
    return (await decode(beforeBytes), await decode(afterBytes));
  },
);

/// Avant / après côte à côte (l'avant n'apparaît que s'il existe).
class BeforeAfterPair extends StatelessWidget {
  const BeforeAfterPair({super.key, required this.afterPath, this.beforeMediaId});
  final String? beforeMediaId;
  final String afterPath;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget tile(Widget image, String label, {bool accent = false}) => Expanded(
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Corner.medium),
          child: Stack(
            fit: StackFit.expand,
            children: [
              image,
              Positioned(
                left: Space.x2,
                bottom: Space.x2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: Space.x3, vertical: Space.x1),
                  decoration: ShapeDecoration(
                    color: accent ? NalviumColors.accent : NalviumColors.primary,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    label,
                    style: NalviumText.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final after = tile(
      // Fond doux pendant le chargement du fichier local.
      ColoredBox(
        color: NalviumColors.surfaceSubtle,
        child: Image.file(
          File(afterPath),
          fit: BoxFit.cover,
          cacheWidth: 720,
          semanticLabel: l10n.afterPhotoSemantics,
          errorBuilder: (_, _, _) => const SizedBox.expand(),
        ),
      ),
      l10n.afterLabel,
      accent: true,
    );
    return Row(
      key: const Key('before-after'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (beforeMediaId != null) ...[
          tile(AuthedImage(mediaId: beforeMediaId!, semanticLabel: l10n.photoSemantics), l10n.beforeLabel),
          const SizedBox(width: Space.x2),
        ],
        after,
      ],
    );
  }
}

/// Fin d'une réparation RÉUSSIE (jamais sur un arrêt de sécurité) : « Prenez une photo du résultat ».
/// La photo reste dans le dossier privé de l'app ; elle ne sort que via « Partager l'avant / après ».
/// [showPair] : afficher l'avant / après ici (le récapitulatif l'affiche déjà en tête).
class AfterPhotoSection extends ConsumerStatefulWidget {
  const AfterPhotoSection({
    super.key,
    required this.sessionId,
    required this.problemTitle,
    this.beforeMediaId,
    this.showPair = true,
  });
  final String sessionId;
  final String problemTitle;
  final String? beforeMediaId;
  final bool showPair;

  @override
  ConsumerState<AfterPhotoSection> createState() => _AfterPhotoSectionState();
}

class _AfterPhotoSectionState extends ConsumerState<AfterPhotoSection> {
  bool _busy = false;

  Future<void> _take() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final photo = await capturePhoto(context, ref);
    if (photo == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(afterPhotosProvider.notifier).save(widget.sessionId, photo.path);
      HapticFeedback.lightImpact();
      messenger.showSnackBar(SnackBar(key: const Key('after-photo-saved'), content: Text(l10n.afterPhotoSaved)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.cameraError)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share(String afterPath) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    final (before, after) = await ref.read(beforeAfterImagesProvider)(widget.beforeMediaId, afterPath);
    if (!mounted) {
      before?.dispose();
      after?.dispose();
      return;
    }
    try {
      await shareCard(
        context,
        ref,
        card: BeforeAfterShareCard(
          lead: l10n.shareBeforeAfterLead,
          title: widget.problemTitle.trim().isEmpty ? l10n.untitledProblem : widget.problemTitle.trim(),
          beforeLabel: l10n.beforeLabel,
          afterLabel: l10n.afterLabel,
          disclaimer: l10n.shareBeforeAfterDisclaimer,
          before: before,
          after: after,
        ),
        text: l10n.shareBeforeAfterText,
        fileName: 'nalvium-avant-apres.png',
      );
    } finally {
      before?.dispose();
      after?.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final afterPath = ref.watch(afterPhotosProvider)[widget.sessionId];
    final Widget child;
    if (afterPath == null) {
      child = _PromptTile(key: const Key('after-photo-take'), busy: _busy, onTap: _take);
    } else {
      child = Column(
        key: const Key('after-photo-done'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showPair) ...[
            BeforeAfterPair(beforeMediaId: widget.beforeMediaId, afterPath: afterPath),
            const SizedBox(height: Space.x3),
          ],
          // La carte « Avant / après » n'a de sens qu'avec les deux photos.
          if (widget.beforeMediaId != null)
            SecondaryButton(
              key: const Key('share-before-after'),
              label: l10n.shareBeforeAfter,
              icon: Icons.ios_share_rounded,
              onPressed: _busy ? null : () => _share(afterPath),
            ),
          TertiaryButton(
            key: const Key('after-photo-retake'),
            label: l10n.afterPhotoRetake,
            color: NalviumColors.textSecondary,
            onPressed: _busy ? null : _take,
          ),
        ],
      );
    }
    return AnimatedSwitcher(duration: motionDuration(context, const Duration(milliseconds: 280)), child: child);
  }
}

/// Proposition discrète : une ligne, icône viseur, jamais bloquante.
class _PromptTile extends StatelessWidget {
  const _PromptTile({super.key, required this.busy, required this.onTap});
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      child: Material(
        color: NalviumColors.surface,
        borderRadius: BorderRadius.circular(Corner.medium),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: busy ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(Space.x4),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: NalviumColors.accentSoft, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.add_a_photo_outlined, color: NalviumColors.primaryText, size: 22),
                ),
                const SizedBox(width: Space.x3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.afterPhotoTitle, style: NalviumText.title.copyWith(fontSize: 16.5)),
                      const SizedBox(height: 2),
                      Text(l10n.afterPhotoBody, style: NalviumText.caption),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: NalviumColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
