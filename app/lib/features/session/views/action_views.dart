import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/nalvium_colors.dart';
import '../../../core/theme/nalvium_spacing.dart';
import '../../../core/theme/nalvium_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/authed_image.dart';
import '../../../core/widgets/choice_tile.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/viewfinder.dart';
import '../../../domain/session.dart';
import '../../../l10n/app_localizations.dart';

/// Actions que les vues déclenchent ; l'écran de session les relie au backend.
class SessionActions {
  const SessionActions({
    required this.onAnswer,
    required this.onActionResult,
    required this.onTakePhoto,
    required this.onHome,
    required this.onRepairOptions,
    required this.onSummary,
    this.onSaveEquipment,
    this.onShareSolution,
  });
  final void Function(String text) onAnswer;
  final void Function(ActionChoice choice) onActionResult;
  final VoidCallback onTakePhoto;
  final VoidCallback onHome;
  final VoidCallback onRepairOptions;
  final VoidCallback onSummary;

  /// Proposition SECONDAIRE après résolution (null = déjà lié à un équipement : rien à proposer).
  final VoidCallback? onSaveEquipment;

  /// Proposition SECONDAIRE après résolution : partager la solution à la Communauté (jamais automatique).
  final VoidCallback? onShareSolution;
}

/// « Arrêtez-vous ici. » est déjà le titre de l'écran : on le retire du corps pour ne pas le répéter.
String stripStopPrefix(String message) {
  final trimmed = message.trim();
  const prefix = 'Arrêtez-vous ici.';
  return trimmed.toLowerCase().startsWith(prefix.toLowerCase())
      ? trimmed.substring(prefix.length).trim()
      : trimmed;
}

enum Phase { observation, action, control }

/// Où l'on en est, qualitativement (jamais « étape 2/7 » : on ne connaît pas le nombre d'étapes).
/// Une pastille discrète : icône + libellé, pour s'orienter sans que ce soit un titre.
class PhaseLabel extends StatelessWidget {
  const PhaseLabel(this.phase, {super.key});
  final Phase phase;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (IconData icon, String text) = switch (phase) {
      Phase.observation => (Icons.visibility_outlined, l10n.phaseObservation),
      Phase.action => (Icons.touch_app_outlined, l10n.phaseAction),
      Phase.control => (Icons.fact_check_outlined, l10n.phaseControl),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.x3, vertical: 5),
      decoration: BoxDecoration(
        color: NalviumColors.primarySoft,
        borderRadius: BorderRadius.circular(Corner.small),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: NalviumColors.primaryText),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              key: const Key('phase-label'),
              style: NalviumText.caption.copyWith(
                color: NalviumColors.primaryText,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Structure commune : pastille → état de Nalvium (discret) → HÉROS (la question / l'action).
/// Le passage d'un action_type à l'autre se lit comme la suite du même diagnostic.
class _Head extends StatelessWidget {
  const _Head({
    required this.phase,
    required this.title,
    required this.hero,
    this.accentBar = false,
    this.heroSize = 24,
  });
  final Phase phase;
  final String title;
  final String hero;
  final bool accentBar;
  final double heroSize;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      hero,
      key: const Key('nalvium-message'),
      style: NalviumText.titleLarge.copyWith(
        fontSize: heroSize,
        height: 1.32,
        fontWeight: accentBar ? FontWeight.w600 : FontWeight.w700,
        letterSpacing: -0.3,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PhaseLabel(phase),
        const SizedBox(height: Space.x4),
        Semantics(
          header: true,
          child: Text(
            title,
            key: const Key('guidance-title'),
            style: NalviumText.title.copyWith(
              fontSize: 18,
              color: NalviumColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: Space.x3),
        if (accentBar)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: NalviumColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: Space.x4),
                Expanded(child: text),
              ],
            ),
          )
        else
          text,
      ],
    );
  }
}

/// Icône d'une réponse connue (neutre : « Oui » n'est pas forcément « bon » selon la question).
IconData? _iconForAnswer(String label) => switch (label.trim().toLowerCase()) {
  'oui' => Icons.check_rounded,
  'un peu' => Icons.contrast_rounded,
  'non' => Icons.close_rounded,
  'je ne sais pas' => Icons.help_outline_rounded,
  _ => null,
};

/// ASK_QUESTION : la question est le centre de l'écran, les réponses sont secondaires.
class AskQuestionView extends StatefulWidget {
  const AskQuestionView({super.key, required this.step, required this.actions});
  final NextStep step;
  final SessionActions actions;

  @override
  State<AskQuestionView> createState() => _AskQuestionViewState();
}

class _AskQuestionViewState extends State<AskQuestionView> {
  late bool _typing = widget.step.choices.isEmpty;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final choices = widget.step.choices;
    // Icônes seulement si toutes les réponses en ont une (sinon la liste paraît incohérente).
    final useIcons =
        choices.isNotEmpty && choices.every((c) => _iconForAnswer(c) != null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Head(
          phase: Phase.observation,
          title: l10n.titleAsk,
          hero: widget.step.message,
          heroSize: 25,
        ),
        const SizedBox(height: Space.x8),
        for (final c in choices) ...[
          ChoiceTile(
            key: Key('choice-$c'),
            label: c,
            icon: useIcons ? _iconForAnswer(c) : null,
            onTap: () => widget.actions.onAnswer(c),
          ),
          const SizedBox(height: Space.x3),
        ],
        if (_typing) ...[
          TextField(
            key: const Key('answer-field'),
            controller: _controller,
            minLines: 1,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(hintText: l10n.typeAnswer),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: Space.x3),
          PrimaryButton(
            key: const Key('send-answer'),
            label: l10n.send,
            onPressed: _controller.text.trim().isEmpty
                ? null
                : () => widget.actions.onAnswer(_controller.text.trim()),
          ),
        ] else
          Align(
            alignment: Alignment.centerLeft,
            child: TertiaryButton(
              key: const Key('answer-otherwise'),
              label: l10n.answerOtherwise,
              onPressed: () => setState(() => _typing = true),
            ),
          ),
      ],
    );
  }
}

/// REQUEST_PHOTO : on voit QUOI photographier — votre photo → la vue demandée.
class RequestPhotoView extends StatelessWidget {
  const RequestPhotoView({
    super.key,
    required this.step,
    required this.actions,
    this.previousMediaId,
    this.previousIsVideo = false,
  });
  final NextStep step;
  final SessionActions actions;
  final String? previousMediaId;
  final bool previousIsVideo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Head(
          phase: Phase.observation,
          title: l10n.titleRequestPhoto,
          hero: step.message,
          heroSize: 22,
        ),
        const SizedBox(height: Space.x6),
        _PhotoPair(
          previousMediaId: previousMediaId,
          previousIsVideo: previousIsVideo,
          onTake: actions.onTakePhoto,
        ),
        const SizedBox(height: Space.x6),
        PrimaryButton(
          key: const Key('take-requested-photo'),
          label: l10n.takeThePhoto,
          icon: Icons.photo_camera_rounded,
          onPressed: actions.onTakePhoto,
        ),
        const SizedBox(height: Space.x1),
        TertiaryButton(
          key: const Key('cannot-take-photo'),
          label: l10n.cannotTakePhoto,
          color: NalviumColors.textSecondary,
          onPressed: () => actions.onAnswer(l10n.cannotTakePhotoAnswer),
        ),
      ],
    );
  }
}

class _PhotoPair extends StatelessWidget {
  const _PhotoPair({this.previousMediaId, this.previousIsVideo = false, required this.onTake});
  final String? previousMediaId;
  final bool previousIsVideo;
  final VoidCallback onTake;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final target = Semantics(
      button: true,
      label: l10n.takeThePhoto,
      excludeSemantics: true,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 4 / 5,
            child: Material(
              color: NalviumColors.primarySoft,
              borderRadius: BorderRadius.circular(Corner.medium),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const Key('photo-target'),
                onTap: onTake,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(10),
                      child: ViewfinderCorners(
                        color: NalviumColors.primary,
                        length: 20,
                        stroke: 3,
                        radius: 10,
                      ),
                    ),
                    const Center(
                      child: Icon(
                        Icons.photo_camera_outlined,
                        size: 34,
                        color: NalviumColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.x2),
          Text(
            l10n.photoToTake,
            style: NalviumText.caption.copyWith(
              color: NalviumColors.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (previousMediaId == null) {
      return Center(child: SizedBox(width: 150, child: target));
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 4 / 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Corner.medium),
                  child: AuthedImage(
                    mediaId: previousMediaId!,
                    semanticLabel: l10n.photoSemantics,
                  ),
                ),
              ),
              const SizedBox(height: Space.x2),
              Text(previousIsVideo ? l10n.yourVideo : l10n.yourPhoto, style: NalviumText.caption),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: Space.x3, vertical: 54),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 22,
            color: NalviumColors.textMuted,
          ),
        ),
        Expanded(child: target),
      ],
    );
  }
}

/// INSTRUCTION : l'action est le héros — une phrase, un trait bleu, puis trois boutons hiérarchisés.
class InstructionView extends StatelessWidget {
  const InstructionView({super.key, required this.step, required this.actions});
  final NextStep step;
  final SessionActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Head(
          phase: Phase.action,
          title: l10n.titleInstruction,
          hero: step.message,
          accentBar: true,
          heroSize: 25,
        ),
        if (step.requiredItems.isNotEmpty) ...[
          const SizedBox(height: Space.x6),
          Text(
            l10n.youNeed,
            key: const Key('required-items-title'),
            style: NalviumText.caption.copyWith(color: NalviumColors.textMuted),
          ),
          const SizedBox(height: Space.x2),
          Wrap(
            spacing: Space.x2,
            runSpacing: Space.x2,
            children: [
              for (final item in step.requiredItems)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.x3,
                    vertical: Space.x2,
                  ),
                  decoration: BoxDecoration(
                    color: NalviumColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(Corner.small),
                  ),
                  child: Text(
                    item,
                    style: NalviumText.body.copyWith(
                      color: NalviumColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: Space.x8),
        PrimaryButton(
          key: const Key('action-done'),
          label: l10n.actionDone,
          onPressed: () => actions.onActionResult(ActionChoice.done),
        ),
        const SizedBox(height: Space.x3),
        SecondaryButton(
          key: const Key('action-cannot'),
          label: l10n.actionCannot,
          onPressed: () => actions.onActionResult(ActionChoice.cannot),
        ),
        const SizedBox(height: Space.x1),
        TertiaryButton(
          key: const Key('action-mismatch'),
          label: l10n.actionMismatch,
          color: NalviumColors.textSecondary,
          onPressed: () => actions.onActionResult(ActionChoice.mismatch),
        ),
      ],
    );
  }
}

/// VERIFICATION : les réponses se lisent comme des RÉSULTATS (grille 2×2 avec icônes), pas un questionnaire.
class VerificationView extends StatelessWidget {
  const VerificationView({
    super.key,
    required this.step,
    required this.actions,
  });
  final NextStep step;
  final SessionActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final choices = step.choices.isNotEmpty
        ? step.choices
        : [
            l10n.answerYes,
            l10n.answerALittle,
            l10n.answerNo,
            l10n.answerDontKnow,
          ];
    final grid =
        choices.length == 4 && choices.every((c) => _iconForAnswer(c) != null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Head(
          phase: Phase.control,
          title: l10n.titleVerification,
          hero: step.message,
          heroSize: 24,
        ),
        const SizedBox(height: Space.x8),
        if (grid)
          LayoutBuilder(
            builder: (context, c) {
              final w = (c.maxWidth - Space.x3) / 2;
              return Wrap(
                spacing: Space.x3,
                runSpacing: Space.x3,
                children: [
                  for (final choice in choices)
                    SizedBox(
                      width: w,
                      child: ChoiceTile(
                        key: Key('choice-$choice'),
                        label: choice,
                        icon: _iconForAnswer(choice),
                        vertical: true,
                        onTap: () => actions.onAnswer(choice),
                      ),
                    ),
                ],
              );
            },
          )
        else
          for (final c in choices) ...[
            ChoiceTile(
              key: Key('choice-$c'),
              label: c,

              onTap: () => actions.onAnswer(c),
            ),
            const SizedBox(height: Space.x3),
          ],
        const SizedBox(height: Space.x2),
        Align(
          alignment: Alignment.centerLeft,
          child: TertiaryButton(
            key: const Key('verify-with-photo'),
            label: l10n.verifyWithPhoto,
            onPressed: actions.onTakePhoto,
          ),
        ),
      ],
    );
  }
}

/// SAFETY_STOP : change immédiatement de niveau d'attention. Aucune action DIY, aucun bouton de réparation.
class SafetyStopView extends StatelessWidget {
  const SafetyStopView({super.key, required this.step, required this.actions});
  final NextStep step;
  final SessionActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Space.x6),
        Center(
          child: Container(
            width: 92,
            height: 92,
            decoration: const BoxDecoration(
              color: NalviumColors.dangerSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              size: 50,
              color: NalviumColors.danger,
            ),
          ),
        ),
        const SizedBox(height: Space.x6),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(
            l10n.safetyTitle,
            key: const Key('safety-title'),
            textAlign: TextAlign.center,
            style: NalviumText.display.copyWith(
              color: NalviumColors.dangerText,
            ),
          ),
        ),
        const SizedBox(height: Space.x5),
        Text(
          stripStopPrefix(step.message),
          key: const Key('safety-message'),
          textAlign: TextAlign.center,
          style: NalviumText.bodyLarge.copyWith(height: 1.5),
        ),
        const SizedBox(height: Space.x10),
        // Une intervention humaine est appropriée : « Demander de l'aide » est l'action principale.
        PrimaryButton(
          key: const Key('safety-find-pro'),
          label: l10n.helpAsk,
          onPressed: actions.onRepairOptions,
        ),
        const SizedBox(height: Space.x2),
        SecondaryButton(
          key: const Key('safety-understood'),
          label: l10n.understoodShort,
          onPressed: actions.onHome,
        ),
      ],
    );
  }
}

/// RECOMMEND_PROFESSIONAL : calme, pas alarmiste.
class ProfessionalView extends StatelessWidget {
  const ProfessionalView({
    super.key,
    required this.step,
    required this.actions,
  });
  final NextStep step;
  final SessionActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final generic = {
      'Cette intervention nécessite un professionnel.',
      l10n.titleProfessional,
    };
    final showMessage = !generic.contains(step.message.trim());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Space.x4),
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: NalviumColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.engineering_rounded,
              size: 40,
              color: NalviumColors.primary,
            ),
          ),
        ),
        const SizedBox(height: Space.x6),
        Semantics(
          header: true,
          child: Text(
            l10n.titleProfessional,
            key: const Key('pro-title'),
            textAlign: TextAlign.center,
            style: NalviumText.titleLarge,
          ),
        ),
        if (showMessage) ...[
          const SizedBox(height: Space.x4),
          Text(
            step.message,
            key: const Key('nalvium-message'),
            textAlign: TextAlign.center,
            style: NalviumText.bodyLarge,
          ),
        ],
        const SizedBox(height: Space.x8),
        PrimaryButton(
          key: const Key('see-repair-options'),
          label: l10n.askForHelp,
          onPressed: actions.onRepairOptions,
        ),
        const SizedBox(height: Space.x1),
        TertiaryButton(
          key: const Key('pro-home'),
          label: l10n.backToHome,
          color: NalviumColors.textSecondary,
          onPressed: actions.onHome,
        ),
      ],
    );
  }
}

/// RESOLVED : « Nalvium m'a aidé ». Une surface de succès très légère, un check qui se pose, une conclusion lisible.
class ResolvedView extends StatefulWidget {
  const ResolvedView({
    super.key,
    required this.step,
    required this.actions,
    this.problemTitle,
  });
  final NextStep step;
  final SessionActions actions;
  final String? problemTitle;

  @override
  State<ResolvedView> createState() => _ResolvedViewState();
}

class _ResolvedViewState extends State<ResolvedView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Animation<double> _iv(double a, double b, Curve curve) => CurvedAnimation(
    parent: _c,
    curve: Interval(a, b, curve: curve),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ring = _iv(0.0, 0.5, Curves.easeOutCubic);
    final check = _iv(0.2, 0.65, Curves.easeOutBack);
    final text = _iv(0.45, 0.9, Curves.easeOutCubic);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Space.x2),
        Container(
          padding: const EdgeInsets.fromLTRB(
            Space.x6,
            Space.x8,
            Space.x6,
            Space.x8,
          ),
          decoration: BoxDecoration(
            color: NalviumColors.successSoft.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(Corner.large),
          ),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _c,
                builder: (context, _) => SizedBox(
                  width: 132,
                  height: 132,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: ring.value.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.7 + 0.3 * ring.value,
                          child: Container(
                            width: 132,
                            height: 132,
                            decoration: const BoxDecoration(
                              color: NalviumColors.successSoft,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: check.value.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.6 + 0.4 * check.value,
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: const BoxDecoration(
                              color: NalviumColors.success,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 52,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Space.x5),
              FadeTransition(
                opacity: text,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.08),
                    end: Offset.zero,
                  ).animate(text),
                  child: Column(
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          l10n.titleResolved,
                          key: const Key('resolved-title'),
                          textAlign: TextAlign.center,
                          style: NalviumText.display,
                        ),
                      ),
                      if (widget.problemTitle != null &&
                          widget.problemTitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: Space.x2),
                        Text(
                          widget.problemTitle!,
                          key: const Key('resolved-problem'),
                          textAlign: TextAlign.center,
                          style: NalviumText.title.copyWith(
                            fontSize: 17,
                            color: NalviumColors.success,
                          ),
                        ),
                      ],
                      const SizedBox(height: Space.x4),
                      Text(
                        widget.step.message,
                        key: const Key('nalvium-message'),
                        textAlign: TextAlign.center,
                        style: NalviumText.bodyLarge.copyWith(
                          fontSize: 18,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.x8),
        PrimaryButton(
          key: const Key('resolved-finish'),
          label: l10n.finish,
          onPressed: widget.actions.onHome,
        ),
        const SizedBox(height: Space.x1),
        TertiaryButton(
          key: const Key('resolved-summary'),
          label: l10n.seeSummary,
          onPressed: widget.actions.onSummary,
        ),
        if (widget.actions.onShareSolution != null)
          TertiaryButton(
            key: const Key('resolved-share'),
            label: l10n.cmShareSolution,
            color: NalviumColors.textSecondary,
            onPressed: widget.actions.onShareSolution,
          ),
        if (widget.actions.onSaveEquipment != null)
          TertiaryButton(
            key: const Key('resolved-save-equipment'),
            label: l10n.eqLinkSave,
            color: NalviumColors.textSecondary,
            onPressed: widget.actions.onSaveEquipment,
          ),
      ],
    );
  }
}
