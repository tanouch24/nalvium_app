import 'package:flutter/material.dart';

import '../../core/widgets/status_chip.dart';
import '../../domain/session.dart';
import '../../l10n/app_localizations.dart';

String categoryLabel(AppLocalizations l10n, String? category) =>
    switch (category) {
      'plumbing' => l10n.catPlumbing,
      'appliance' => l10n.catAppliance,
      'handyman' => l10n.catHandyman,
      'electrical' => l10n.catElectrical,
      'other' => '', // « Autre » n'apprend rien à l'utilisateur
      _ => '',
    };

String sessionTitle(AppLocalizations l10n, SessionSummary s) =>
    (s.title != null && s.title!.trim().isNotEmpty)
    ? s.title!
    : l10n.untitledProblem;

/// Libellé d'état d'une session ACTIVE (où l'on en est).
String sessionStateLabel(AppLocalizations l10n, SessionSummary s) =>
    switch (s.currentState) {
      'ASK_QUESTION' => l10n.stateAskQuestion,
      'REQUEST_PHOTO' => l10n.stateRequestPhoto,
      'INSTRUCTION' => l10n.stateInstruction,
      'VERIFICATION' => l10n.stateVerification,
      'awaiting_analysis' => l10n.stateAwaiting,
      _ => l10n.statusActive,
    };

String sessionStatusLabel(AppLocalizations l10n, SessionSummary s) =>
    switch (s.status) {
      'resolved' => l10n.statusResolved,
      'stopped' => l10n.statusStopped,
      'referred' => l10n.statusReferred,
      _ => l10n.statusActive,
    };

StatusTone sessionTone(String status) => switch (status) {
  'resolved' => StatusTone.success,
  'stopped' => StatusTone.danger,
  'referred' => StatusTone.neutral,
  _ => StatusTone.info,
};

IconData sessionIcon(String status) => switch (status) {
  'resolved' => Icons.check_circle_rounded,
  'stopped' => Icons.warning_amber_rounded,
  'referred' => Icons.engineering_rounded,
  _ => Icons.schedule_rounded,
};

const _months = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

String _hm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Date relative : « Aujourd'hui, 15:45 », « Hier », « 12 sept. ».
String relativeDate(AppLocalizations l10n, DateTime date, {DateTime? now}) {
  final d = date.toLocal();
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return '${l10n.relToday}, ${_hm(d)}';
  if (diff == 1) return l10n.relYesterday;
  return '${d.day} ${_months[d.month - 1]}${d.year != n.year ? ' ${d.year}' : ''}';
}
