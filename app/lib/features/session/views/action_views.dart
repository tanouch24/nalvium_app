import 'package:flutter/material.dart';

import '../../../core/theme/nalvium_colors.dart';
import '../../../core/theme/nalvium_spacing.dart';
import '../../../domain/session.dart';
import '../../../l10n/app_localizations.dart';

/// Actions que les vues peuvent déclencher ; l'écran de session les relie au backend.
class SessionActions {
  const SessionActions({
    required this.onAnswer,
    required this.onActionResult,
    required this.onTakePhoto,
    required this.onHome,
    required this.onRepairOptions,
  });
  final void Function(String text) onAnswer;
  final void Function(ActionChoice choice) onActionResult;
  final VoidCallback onTakePhoto;
  final VoidCallback onHome;
  final VoidCallback onRepairOptions;
}

/// « Arrêtez-vous ici. » est déjà le titre de l'écran : on le retire du corps pour ne pas le répéter.
String stripStopPrefix(String message) {
  final trimmed = message.trim();
  const prefix = 'Arrêtez-vous ici.';
  return trimmed.toLowerCase().startsWith(prefix.toLowerCase()) ? trimmed.substring(prefix.length).trim() : trimmed;
}

class NalviumMessage extends StatelessWidget {
  const NalviumMessage(this.text, {super.key, this.label});
  final String text;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label ?? AppLocalizations.of(context).appName,
          style: theme.textTheme.labelLarge?.copyWith(color: NalviumColors.blue, letterSpacing: 2, fontSize: 13, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: NalviumSpacing.sm),
        Text(text, key: const Key('nalvium-message'), style: theme.textTheme.bodyLarge?.copyWith(fontSize: 20, height: 1.4, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _ChoiceButtons extends StatelessWidget {
  const _ChoiceButtons({required this.choices, required this.onPick});
  final List<String> choices;
  final void Function(String) onPick;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in choices) ...[
            OutlinedButton(key: Key('choice-$c'), onPressed: () => onPick(c), child: Text(c)),
            const SizedBox(height: NalviumSpacing.sm),
          ],
        ],
      );
}

/// ASK_QUESTION : UNE question, réponses adaptées, réponse libre possible.
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

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) widget.actions.onAnswer(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NalviumMessage(widget.step.message),
        const SizedBox(height: NalviumSpacing.lg),
        if (widget.step.choices.isNotEmpty) _ChoiceButtons(choices: widget.step.choices, onPick: widget.actions.onAnswer),
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
          const SizedBox(height: NalviumSpacing.sm),
          FilledButton(key: const Key('send-answer'), onPressed: _controller.text.trim().isEmpty ? null : _submit, child: Text(l10n.send)),
        ] else
          TextButton(key: const Key('answer-otherwise'), onPressed: () => setState(() => _typing = true), child: Text(l10n.answerOtherwise)),
      ],
    );
  }
}

/// REQUEST_PHOTO : dit exactement ce qu'il veut voir.
class RequestPhotoView extends StatelessWidget {
  const RequestPhotoView({super.key, required this.step, required this.actions});
  final NextStep step;
  final SessionActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NalviumMessage(step.message),
        const SizedBox(height: NalviumSpacing.lg),
        FilledButton.icon(
          key: const Key('take-requested-photo'),
          onPressed: actions.onTakePhoto,
          icon: const Icon(Icons.photo_camera_rounded),
          label: Text(l10n.takeAPhoto),
        ),
        TextButton(
          key: const Key('cannot-take-photo'),
          onPressed: () => actions.onAnswer(l10n.cannotTakePhotoAnswer),
          child: Text(l10n.cannotTakePhoto),
        ),
      ],
    );
  }
}

/// INSTRUCTION : UNE seule action à la fois.
class InstructionView extends StatelessWidget {
  const InstructionView({super.key, required this.step, required this.actions});
  final NextStep step;
  final SessionActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (step.stepNumber != null)
          Padding(
            padding: const EdgeInsets.only(bottom: NalviumSpacing.sm),
            child: Text(l10n.stepLabel(step.stepNumber!), key: const Key('step-label'), style: theme.textTheme.titleMedium?.copyWith(color: NalviumColors.grey)),
          ),
        NalviumMessage(step.message),
        if (step.requiredItems.isNotEmpty) ...[
          const SizedBox(height: NalviumSpacing.md),
          Text(l10n.youWillNeed(step.requiredItems.join(', ')), style: theme.textTheme.bodyMedium),
        ],
        const SizedBox(height: NalviumSpacing.lg),
        FilledButton(key: const Key('action-done'), onPressed: () => actions.onActionResult(ActionChoice.done), child: Text(l10n.actionDone)),
        const SizedBox(height: NalviumSpacing.sm),
        OutlinedButton(key: const Key('action-cannot'), onPressed: () => actions.onActionResult(ActionChoice.cannot), child: Text(l10n.actionCannot)),
        TextButton(key: const Key('action-mismatch'), onPressed: () => actions.onActionResult(ActionChoice.mismatch), child: Text(l10n.actionMismatch)),
      ],
    );
  }
}

/// VERIFICATION : vérifier le résultat plutôt que de supposer.
class VerificationView extends StatelessWidget {
  const VerificationView({super.key, required this.step, required this.actions});
  final NextStep step;
  final SessionActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final choices = step.choices.isNotEmpty ? step.choices : [l10n.answerNo, l10n.answerYes, l10n.answerDontKnow];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NalviumMessage(step.message),
        const SizedBox(height: NalviumSpacing.lg),
        _ChoiceButtons(choices: choices, onPick: actions.onAnswer),
        TextButton.icon(
          key: const Key('verify-with-photo'),
          onPressed: actions.onTakePhoto,
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(l10n.takeAPhoto),
        ),
      ],
    );
  }
}

/// SAFETY_STOP : immédiatement identifiable, sans aucune autre action que partir.
class SafetyStopView extends StatelessWidget {
  const SafetyStopView({super.key, required this.step, required this.actions});
  final NextStep step;
  final SessionActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: NalviumSpacing.lg),
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(color: NalviumColors.danger, shape: BoxShape.circle),
            child: const Icon(Icons.front_hand_rounded, size: 42, color: Colors.white),
          ),
        ),
        const SizedBox(height: NalviumSpacing.lg),
        Text(l10n.safetyTitle, key: const Key('safety-title'), textAlign: TextAlign.center, style: theme.textTheme.headlineLarge?.copyWith(color: NalviumColors.danger)),
        const SizedBox(height: NalviumSpacing.md),
        Text(stripStopPrefix(step.message), key: const Key('safety-message'), textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 19)),
        const SizedBox(height: NalviumSpacing.xl),
        FilledButton(
          key: const Key('safety-understood'),
          style: FilledButton.styleFrom(backgroundColor: NalviumColors.navy),
          onPressed: actions.onHome,
          child: Text(l10n.understood),
        ),
      ],
    );
  }
}

/// RECOMMEND_PROFESSIONAL : orientation simple vers l'onglet Dépannage.
class ProfessionalView extends StatelessWidget {
  const ProfessionalView({super.key, required this.step, required this.actions});
  final NextStep step;
  final SessionActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Le titre fixe suffit si le message de l'IA est le même.
    final showMessage = step.message.trim() != l10n.proTitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: NalviumSpacing.md),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(color: NalviumColors.blueSoft, shape: BoxShape.circle),
            child: const Icon(Icons.engineering_rounded, size: 38, color: NalviumColors.blue),
          ),
        ),
        const SizedBox(height: NalviumSpacing.lg),
        Text(l10n.proTitle, key: const Key('pro-title'), textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
        if (showMessage) ...[
          const SizedBox(height: NalviumSpacing.md),
          Text(step.message, key: const Key('nalvium-message'), textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
        ],
        const SizedBox(height: NalviumSpacing.xl),
        FilledButton(key: const Key('see-repair-options'), onPressed: actions.onRepairOptions, child: Text(l10n.seeRepairOptions)),
        TextButton(key: const Key('pro-home'), onPressed: actions.onHome, child: Text(l10n.backHome)),
      ],
    );
  }
}

/// RESOLVED : seulement lorsque Nalvium a vérifié.
class ResolvedView extends StatelessWidget {
  const ResolvedView({super.key, required this.step, required this.actions});
  final NextStep step;
  final SessionActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: NalviumSpacing.md),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(color: NalviumColors.success, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, size: 44, color: Colors.white),
          ),
        ),
        const SizedBox(height: NalviumSpacing.lg),
        Text(l10n.resolvedTitle, key: const Key('resolved-title'), textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
        const SizedBox(height: NalviumSpacing.md),
        Text(step.message, key: const Key('nalvium-message'), textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
        const SizedBox(height: NalviumSpacing.xl),
        FilledButton(key: const Key('resolved-finish'), onPressed: actions.onHome, child: Text(l10n.finish)),
      ],
    );
  }
}
