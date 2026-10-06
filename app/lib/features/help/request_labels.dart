import 'package:flutter/material.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../domain/service_request.dart';
import '../../l10n/app_localizations.dart';

String requestStatusLabel(AppLocalizations l10n, RequestStatus s) => switch (s) {
  RequestStatus.draft => l10n.requestStatusDraft,
  RequestStatus.submitted => l10n.requestStatusSubmitted,
  RequestStatus.contactPending => l10n.requestStatusPending,
  RequestStatus.contacted => l10n.requestStatusContacted,
  RequestStatus.closed => l10n.requestStatusClosed,
  RequestStatus.cancelled => l10n.requestStatusCancelled,
};

IconData requestStatusIcon(RequestStatus s) => switch (s) {
  RequestStatus.cancelled => Icons.cancel_outlined,
  RequestStatus.closed || RequestStatus.contacted => Icons.check_circle_rounded,
  _ => Icons.schedule_send_rounded,
};

Color requestStatusColor(RequestStatus s) => switch (s) {
  RequestStatus.cancelled => NalviumColors.textSecondary,
  RequestStatus.closed || RequestStatus.contacted => NalviumColors.success,
  _ => NalviumColors.primaryText,
};

String availabilityLabel(AppLocalizations l10n, ServiceRequest r) {
  switch (r.availability) {
    case AvailabilityType.asap:
      return l10n.helpAsap;
    case AvailabilityType.today:
      return l10n.helpToday;
    case AvailabilityType.tomorrow:
      return l10n.helpTomorrow;
    case AvailabilityType.thisWeek:
      return l10n.helpThisWeek;
    case AvailabilityType.custom:
      final w = switch (r.timeWindow) { 'morning' => l10n.helpMorning, 'afternoon' => l10n.helpAfternoon, 'evening' => l10n.helpEvening, _ => '' };
      final d = r.preferredDate == null ? '' : _fr(r.preferredDate!);
      return [d, w].where((e) => e.isNotEmpty).join(' · ');
    case null:
      return '';
  }
}

String _fr(String iso) {
  final p = iso.split('-');
  return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : iso;
}
