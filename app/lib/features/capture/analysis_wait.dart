import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/viewfinder.dart';
import '../../l10n/app_localizations.dart';

/// Rythme des étapes narrées : la dernière est atteinte vers 7 s, l'analyse dure ≈10 s.
const kAnalysisStepEvery = Duration(milliseconds: 2400);

/// L'attente (≈10 s) : Nalvium observe CET objet. Les coins du viseur respirent très lentement.
/// Sans [steps], les phrases tournent pour rassurer. Avec [steps] (première analyse), une liste narrée avance
/// au rythme d'une minuterie : la DERNIÈRE étape (la vérification sécurité) reste en cours tant que la vraie
/// réponse n'est pas arrivée — l'écran ne prétend jamais avoir fini. Ni pourcentage ni barre de progression.
class AnalysisWait extends StatefulWidget {
  const AnalysisWait({
    super.key,
    this.photo,
    this.title,
    this.subject,
    this.video = false,
    this.refined = false,
    this.lightweight = false,
    this.steps,
    required this.onCancel,
  });

  /// Finition de l'écran d'analyse d'une photo / vidéo / description (composition optique, coins plus fins,
  /// sous-texte aéré). Les autres usages (attente en cours de session) gardent leur rendu actuel.
  final bool refined;

  /// Attente entre deux réponses d'un diagnostic en cours : même langage que l'analyse (coins fins, sous-texte),
  /// plus légère (cadre réduit, titre plus petit) et sans prétendre refaire une analyse complète.
  final bool lightweight;

  /// Photo observée. Null : variante compacte, sans zone d'image.
  final Widget? photo;

  /// Titre (par défaut « J'analyse le problème… »).
  final String? title;

  /// Description écrite par l'utilisateur, rappelée telle quelle (variante sans photo).
  final String? subject;
  final VoidCallback onCancel;

  /// Variante vidéo : même cadre que la photo, première phrase d'attente adaptée.
  final bool video;

  /// Étapes narrées (« Lecture de votre photo… », …). Null : phrases tournantes.
  final List<String>? steps;

  @override
  State<AnalysisWait> createState() => _AnalysisWaitState();
}

class _AnalysisWaitState extends State<AnalysisWait>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  Timer? _timer;
  Timer? _stepTimer;
  int _tick = 0;

  /// Étape en cours (les précédentes sont cochées). Ne dépasse jamais la dernière.
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() => _tick++);
    });
    final steps = widget.steps;
    if (steps != null && steps.length > 1) {
      _stepTimer = Timer.periodic(kAnalysisStepEvery, (t) {
        if (!mounted) return;
        HapticFeedback.selectionClick();
        setState(() => _step++);
        if (_step >= steps.length - 1) t.cancel();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _breath.stop();
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stepTimer?.cancel();
    _breath.dispose();
    super.dispose();
  }

  /// Deux lignes réservées (trois à forte taille de texte) : jamais de texte coupé, jamais de saut de mise en page.
  double _phraseBoxHeight(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final lines = scaler.scale(1) >= 1.5 ? 3 : 2;
    return scaler.scale(16 * 1.45) * lines;
  }

  String _phrase(AppLocalizations l10n) {
    if (_tick >= 5) return l10n.analyzingSlow; // ≈ 25 s
    final first = widget.lightweight
        ? l10n.waitChecking
        : (widget.video ? l10n.waitVideo : l10n.waitLooking);
    return [
      first,
      l10n.waitObserving,
      l10n.waitChecking,
      first,
      l10n.waitObserving,
    ][_tick];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasPhoto = widget.photo != null;
    final frame = AnimatedBuilder(
      animation: _breath,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_breath.value);
        return SizedBox(
          width: hasPhoto
              ? (widget.lightweight ? 224 : 276)
              : (widget.lightweight ? 108 : 124),
          height: hasPhoto
              ? (widget.lightweight ? 272 : 336)
              : (widget.lightweight ? 108 : 124),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: EdgeInsets.all(hasPhoto ? 14 : 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(hasPhoto ? 22 : 20),
                  child:
                      widget.photo ??
                      const ColoredBox(
                        color: NalviumColors.primarySoft,
                        child: Center(
                          child: Icon(
                            Icons.visibility_outlined,
                            size: 40,
                            color: NalviumColors.primary,
                          ),
                        ),
                      ),
                ),
              ),
              // Seuls les coins bougent (4 dp) : la photo, elle, reste immobile.
              ViewfinderCorners(
                color: NalviumColors.primary,
                length: hasPhoto ? (widget.refined ? 30 : 36) : 24,
                stroke: hasPhoto ? (widget.refined ? 3.5 : 4) : 3.5,
                radius: hasPhoto ? (widget.refined ? 18 : 16) : 12,
                inset: (widget.refined ? 4 : 5) * t,
              ),
            ],
          ),
        );
      },
    );

    return Center(
      child: SingleChildScrollView(
        // Raffiné : plus d'air en bas qu'en haut, le bloc se lit au centre optique (un peu au-dessus du milieu).
        padding: widget.refined
            ? const EdgeInsets.fromLTRB(
                Space.gutter,
                Space.x4,
                Space.gutter,
                Space.x14,
              )
            : const EdgeInsets.symmetric(
                horizontal: Space.gutter,
                vertical: Space.x6,
              ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            frame,
            SizedBox(
              height: hasPhoto
                  ? (widget.lightweight ? Space.x6 : Space.x8)
                  : Space.x6,
            ),
            Text(
              widget.title ??
                  (widget.lightweight
                      ? l10n.preparingNext
                      : l10n.analyzingTitle),
              key: const Key('analyzing-title'),
              style: widget.lightweight
                  ? NalviumText.titleLarge.copyWith(fontSize: 24)
                  : NalviumText.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (widget.subject != null &&
                widget.subject!.trim().isNotEmpty) ...[
              const SizedBox(height: Space.x3),
              Text(
                '« ${widget.subject!.trim()} »',
                key: const Key('analysis-subject'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: NalviumText.body.copyWith(
                  color: NalviumColors.textPrimary,
                  fontSize: 16,
                ),
              ),
            ],
            if (widget.steps != null) ...[
              const SizedBox(height: Space.x5),
              _Steps(labels: widget.steps!, current: _step),
              // Ligne réservée : « Annuler » ne bouge pas quand la note « plus long que d'habitude » apparaît.
              SizedBox(
                height: _phraseBoxHeight(context),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedOpacity(
                    opacity: _tick >= 5 ? 1 : 0,
                    duration: motionDuration(
                      context,
                      const Duration(milliseconds: 300),
                    ),
                    child: Text(
                      l10n.analyzingSlow,
                      key: const Key('analysis-slow'),
                      textAlign: TextAlign.center,
                      style: NalviumText.caption,
                    ),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: Space.x3),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: widget.refined ? 300 : double.infinity,
                ),
                child: SizedBox(
                  // Hauteur réservée : le bouton « Annuler » ne bouge pas quand la phrase change.
                  height: widget.refined ? _phraseBoxHeight(context) : 48,
                  child: AnimatedSwitcher(
                    duration: motionDuration(
                      context,
                      const Duration(milliseconds: 500),
                    ),
                    child: Text(
                      _phrase(l10n),
                      key: ValueKey(_phrase(l10n)),
                      style: widget.refined
                          ? NalviumText.body.copyWith(height: 1.45)
                          : NalviumText.body,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
            SizedBox(height: widget.refined ? Space.x3 : Space.x2),
            TertiaryButton(
              key: const Key('cancel-analysis'),
              label: l10n.cancel,
              onPressed: widget.onCancel,
              color: NalviumColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Liste narrée : ✓ fait · indicateur discret = en cours · cercle vide = à venir.
/// Toutes les lignes sont posées dès le départ (rien ne saute) ; seule l'icône change, en fondu bref.
class _Steps extends StatelessWidget {
  const _Steps({required this.labels, required this.current});
  final List<String> labels;
  final int current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final still = reduceMotion(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        key: const Key('analysis-steps'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Space.x1 + 1),
              child: Semantics(
                label:
                    '${labels[i]} ${i < current ? l10n.stepDoneSemantics : (i == current ? l10n.stepCurrentSemantics : '')}'
                        .trim(),
                excludeSemantics: true,
                liveRegion: i == current,
                child: Row(
                  key: Key(
                    'analysis-step-$i-${i < current ? 'done' : (i == current ? 'current' : 'next')}',
                  ),
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: AnimatedSwitcher(
                        duration: motionDuration(
                          context,
                          const Duration(milliseconds: 260),
                        ),
                        switchInCurve: Curves.easeOutCubic,
                        transitionBuilder: (child, a) => FadeTransition(
                          opacity: a,
                          child: ScaleTransition(
                            scale: Tween(begin: 0.6, end: 1.0).animate(a),
                            child: child,
                          ),
                        ),
                        child: i < current
                            ? const Icon(
                                Icons.check_circle_rounded,
                                key: ValueKey('done'),
                                size: 22,
                                color: NalviumColors.success,
                              )
                            : i == current
                            ? Center(
                                key: const ValueKey('current'),
                                child: still
                                    ? Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          color: NalviumColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    : const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: NalviumColors.primary,
                                        ),
                                      ),
                              )
                            : const Icon(
                                Icons.radio_button_unchecked_rounded,
                                key: ValueKey('next'),
                                size: 22,
                                color: NalviumColors.borderSubtle,
                              ),
                      ),
                    ),
                    const SizedBox(width: Space.x3),
                    Flexible(
                      child: Text(
                        labels[i],
                        style: NalviumText.body.copyWith(
                          height: 1.35,
                          color: i == current
                              ? NalviumColors.textPrimary
                              : (i < current
                                    ? NalviumColors.textSecondary
                                    : NalviumColors.textMuted),
                          fontWeight: i == current
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
