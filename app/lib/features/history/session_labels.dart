import '../../domain/session.dart';
import '../../l10n/app_localizations.dart';

String sessionStateLabel(AppLocalizations l10n, SessionSummary s) => switch (s.currentState) {
      'ASK_QUESTION' => l10n.stateAskQuestion,
      'REQUEST_PHOTO' => l10n.stateRequestPhoto,
      'INSTRUCTION' => l10n.stateInstruction,
      'VERIFICATION' => l10n.stateVerification,
      'awaiting_analysis' => l10n.stateAwaiting,
      _ => l10n.statusActive,
    };

String sessionStatusLabel(AppLocalizations l10n, SessionSummary s) => switch (s.status) {
      'resolved' => l10n.statusResolved,
      'stopped' => l10n.statusStopped,
      'referred' => l10n.statusReferred,
      _ => sessionStateLabel(l10n, s),
    };

String sessionTitle(AppLocalizations l10n, SessionSummary s) =>
    (s.title != null && s.title!.trim().isNotEmpty) ? s.title! : l10n.untitledProblem;
