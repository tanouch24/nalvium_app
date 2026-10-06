import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/authed_image.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/viewfinder.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import '../capture/capture_flow.dart';
import '../history/session_labels.dart';

/// Accueil : explique l'app immédiatement. « À reprendre » n'existe que s'il y a une vraie session active.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  Space.gutter,
                  Space.x2,
                  Space.gutter,
                  Space.x8,
                ),
                children: [
                  Row(
                    children: [
                      Text(
                        l10n.appName,
                        style: NalviumText.wordmark,
                        textScaler: TextScaler.noScaling,
                      ),
                      const Spacer(),
                      IconButton(
                        key: const Key('open-history'),
                        tooltip: l10n.history,
                        icon: const Icon(Icons.history_rounded),
                        iconSize: 26,
                        color: NalviumColors.textPrimary,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: () => context.push('/history'),
                      ),
                      IconButton(
                        key: const Key('open-settings'),
                        tooltip: l10n.settings,
                        icon: const Icon(Icons.settings_outlined),
                        iconSize: 26,
                        color: NalviumColors.textPrimary,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: () => context.push('/settings'),
                      ),
                    ],
                  ),
                  const SizedBox(height: Space.x4),
                  Text(
                    l10n.homeGreeting,
                    style: NalviumText.bodyLarge.copyWith(
                      color: NalviumColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: Space.x1),
                  Text(l10n.homeTitle, style: NalviumText.display),
                  const SizedBox(height: Space.x3),
                  Text(
                    l10n.homeSubtitle,
                    style: NalviumText.body.copyWith(
                      fontSize: 17,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: Space.x6),
                  _CaptureCta(
                    title: l10n.takePhoto,
                    hint: l10n.takePhotoHint,
                    onPressed: () => startPhotoCapture(context, ref),
                  ),
                  const SizedBox(height: Space.x3),
                  _SecondaryActions(
                    describeLabel: l10n.describeShort,
                    filmLabel: l10n.filmShort,
                    onDescribe: () => context.push('/describe'),
                    onFilm: () => context.push('/video/capture'),
                  ),
                  const _ResumeSection(),
                ],
              ),
            ),
            // La bannière est gérée au même endroit pour tous les écrans autorisés (AppShell / BannerSlot).
          ],
        ),
      ),
    );
  }
}

/// Décrire / Filmer : deux actions de même poids. À très grande taille de texte, elles s'empilent
/// (pleine largeur, même hauteur) plutôt que de couper un mot en deux.
class _SecondaryActions extends StatelessWidget {
  const _SecondaryActions({
    required this.describeLabel,
    required this.filmLabel,
    required this.onDescribe,
    required this.onFilm,
  });
  final String describeLabel;
  final String filmLabel;
  final VoidCallback onDescribe;
  final VoidCallback onFilm;

  @override
  Widget build(BuildContext context) {
    final describe = SecondaryButton(
      key: const Key('describe-problem'),
      label: describeLabel,
      icon: Icons.edit_note_rounded,
      onPressed: onDescribe,
    );
    final film = SecondaryButton(
      key: const Key('film-problem'),
      label: filmLabel,
      icon: Icons.videocam_outlined,
      onPressed: onFilm,
    );
    if (MediaQuery.textScalerOf(context).scale(1) >= 1.5) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          describe,
          const SizedBox(height: Space.x3),
          film,
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: describe),
          const SizedBox(width: Space.x3),
          Expanded(child: film),
        ],
      ),
    );
  }
}

/// Action signature : UNE seule zone cliquable — la photo (viseur Nalvium superposé) puis une zone CTA propre.
/// Le texte n'est jamais posé sur la photographie : il vit dans la zone bleue, lisible en toutes circonstances.
class _CaptureCta extends StatefulWidget {
  const _CaptureCta({
    required this.title,
    required this.hint,
    required this.onPressed,
  });
  final String title;
  final String hint;
  final VoidCallback onPressed;

  /// Photo lifestyle définitive (le viseur bleu autour de la plomberie fait partie de l'image).
  static const photoAsset = 'assets/images/home_hero.jpg';

  @override
  State<_CaptureCta> createState() => _CaptureCtaState();
}

class _CaptureCtaState extends State<_CaptureCta> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final d = motionDuration(context, const Duration(milliseconds: 120));
    final big = MediaQuery.textScalerOf(context).scale(1) >= 1.3;
    // Forte taille de texte : on recadre la photo plutôt que de réduire la lisibilité du texte.
    final photoHeight = big ? 88.0 : 140.0;
    return Semantics(
      button: true,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: d,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Corner.large),
            boxShadow: [
              BoxShadow(
                color: NalviumColors.textPrimary.withValues(
                  alpha: _pressed ? 0.03 : 0.07,
                ),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: NalviumColors.primary,
            borderRadius: BorderRadius.circular(Corner.large),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const Key('take-photo'),
              onHighlightChanged: (v) => setState(() => _pressed = v),
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.onPressed();
              },
              overlayColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.pressed)
                    ? Colors.white.withValues(alpha: 0.08)
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: photoHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          _CaptureCta.photoAsset,
                          key: const Key('home-photo'),
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, 0.15),
                          cacheWidth: 1080,
                          excludeFromSemantics: true,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Space.x5,
                      Space.x4 + 2,
                      Space.x4,
                      Space.x4 + 2,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.photo_camera_rounded,
                            size: 24,
                            color: NalviumColors.primary,
                          ),
                        ),
                        const SizedBox(width: Space.x4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title,
                                style: NalviumText.title.copyWith(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.hint,
                                style: NalviumText.caption.copyWith(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: Space.x2),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// « À reprendre » : UNIQUEMENT une vraie session active du backend.
/// Elle dit exactement où l'on en était : la photo, le problème, la dernière question/action, Continuer.
class _ResumeSection extends ConsumerWidget {
  const _ResumeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeSessionsProvider).value;
    if (active == null || active.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final s = active.first;
    final last = s.lastMessage?.trim();

    return Padding(
      padding: const EdgeInsets.only(top: Space.x8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.resumeSection, style: NalviumText.title),
          const SizedBox(height: Space.x3),
          Semantics(
            button: true,
            child: Material(
              color: NalviumColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Corner.medium),
                side: const BorderSide(color: NalviumColors.borderSubtle),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const Key('resume-session'),
                onTap: () => context.push('/session/${s.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(Space.x4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 76,
                            height: 76,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: s.firstMediaId == null
                                      ? const ColoredBox(
                                          color: NalviumColors.primarySoft,
                                          child: Icon(
                                            Icons.edit_note_rounded,
                                            color: NalviumColors.primary,
                                            size: 32,
                                          ),
                                        )
                                      : AuthedImage(mediaId: s.firstMediaId!),
                                ),
                                if (s.firstMediaId != null)
                                  ViewfinderCorners(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    length: 10,
                                    stroke: 2,
                                    radius: 4,
                                    inset: 6,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: Space.x4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sessionTitle(l10n, s),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: NalviumText.title.copyWith(
                                    fontSize: 18.5,
                                  ),
                                ),
                                if (last != null && last.isNotEmpty) ...[
                                  const SizedBox(height: Space.x1 + 2),
                                  Text(
                                    last,
                                    key: const Key('resume-last'),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: NalviumText.body.copyWith(
                                      fontSize: 15.5,
                                      color: NalviumColors.textPrimary,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Space.x4),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: Space.x3,
                        runSpacing: Space.x2,
                        children: [
                          Text(
                            relativeDate(l10n, s.updatedAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: NalviumText.caption.copyWith(
                              color: NalviumColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                          Container(
                            constraints: const BoxConstraints(minHeight: 48),
                            padding: const EdgeInsets.symmetric(
                              horizontal: Space.x4,
                            ),
                            decoration: BoxDecoration(
                              color: NalviumColors.primarySoft,
                              borderRadius: BorderRadius.circular(
                                Corner.small + 2,
                              ),
                            ),
                            child: Center(
                              widthFactor: 1,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      l10n.resumeButton,
                                      textAlign: TextAlign.center,
                                      style: NalviumText.button.copyWith(
                                        fontSize: 15,
                                        color: NalviumColors.primaryText,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: NalviumColors.primaryText,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
