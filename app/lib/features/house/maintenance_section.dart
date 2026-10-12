import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/nalvium_colors.dart';
import '../../core/theme/nalvium_spacing.dart';
import '../../core/theme/nalvium_typography.dart';
import '../../core/widgets/motion.dart';
import '../../domain/home_profile.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import '../history/session_labels.dart';
import 'maintenance_reminders.dart';

/// Horloge injectable (les tests figent la date).
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

extension MaintenanceLabels on MaintenanceTask {
  (String, String) labels(AppLocalizations l10n) => switch (id) {
    'boiler' => (l10n.mtBoiler, l10n.mtBoilerBody),
    'radiators' => (l10n.mtRadiators, l10n.mtRadiatorsBody),
    'heat_pump' => (l10n.mtHeatPump, l10n.mtHeatPumpBody),
    'water_heater' => (l10n.mtWaterHeater, l10n.mtWaterHeaterBody),
    'vmc' => (l10n.mtVmc, l10n.mtVmcBody),
    _ => (l10n.mtSmokeAlarm, l10n.mtSmokeAlarmBody),
  };

  IconData get icon => switch (id) {
    'boiler' => Icons.local_fire_department_outlined,
    'radiators' => Icons.thermostat_rounded,
    'heat_pump' => Icons.heat_pump_outlined,
    'water_heater' => Icons.water_drop_outlined,
    'vmc' => Icons.air_rounded,
    _ => Icons.sensors_rounded,
  };
}

/// État lisible d'un entretien : « Dans 12 jours », « En retard », « À planifier ».
String maintenanceStatus(AppLocalizations l10n, MaintenanceTask t, HomeProfile p, DateTime now) {
  final due = t.dueDate(p);
  if (due == null) return l10n.dashToPlan;
  final days = DateTime(due.year, due.month, due.day).difference(DateTime(now.year, now.month, now.day)).inDays;
  return days < 0 ? l10n.dashOverdue : l10n.dashInDays(days);
}

/// Prochain entretien à mettre en avant : d'abord en retard ou à planifier (obligatoires en tête), puis le plus proche.
MaintenanceTask? nextMaintenance(HomeProfile p, DateTime now) {
  final tasks = MaintenanceTask.forProfile(p);
  if (tasks.isEmpty) return null;
  int rank(MaintenanceTask t) {
    final due = t.dueDate(p);
    if (due == null) return t.mandatory ? -2 : -1;
    return due.isBefore(now) ? -3 : due.difference(now).inDays;
  }

  final sorted = [...tasks]..sort((a, b) => rank(a).compareTo(rank(b)));
  return sorted.first;
}

class MaintenanceSection extends ConsumerWidget {
  const MaintenanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = ref.watch(homeProfileProvider);
    final now = ref.watch(clockProvider)();
    final reminders = ref.watch(maintenanceRemindersProvider);
    final since = ref.read(maintenanceRemindersProvider.notifier).since(now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final t in MaintenanceTask.forProfile(p)) ...[
          _TaskRow(
            reminderAt: reminderDateFor(t, p, now, since: since),
            remindersOn: reminders,
            onRemind: () => _remind(context, ref, t),
            task: t,
            status: maintenanceStatus(l10n, t, p, now),
            late: t.dueDate(p)?.isBefore(now) ?? false,
            detail: p.maintenanceDone[t.id] == null
                ? (t.mandatory ? l10n.mtMandatory : null)
                : l10n.mtNext(formatDay(t.dueDate(p)!)),
            onDone: () async {
              HapticFeedback.lightImpact();
              await ref.read(homeProfileProvider.notifier).markMaintenanceDone(t.id, now);
              if (context.mounted) {
                final text = ref.read(maintenanceRemindersProvider) ? l10n.mtMarked : l10n.mtMarkedPlain;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
              }
            },
          ),
          const SizedBox(height: Space.x2),
        ],
      ],
    );
  }
}

/// « Me le rappeler » : l'autorisation de notifier n'est demandée qu'ici (ou dans Réglages), jamais au lancement.
Future<void> _remind(BuildContext context, WidgetRef ref, MaintenanceTask t) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  HapticFeedback.selectionClick();
  final ok = await ref.read(maintenanceRemindersProvider.notifier).enable();
  final now = ref.read(clockProvider)();
  final at = reminderDateFor(t, ref.read(homeProfileProvider), now, since: ref.read(maintenanceRemindersProvider.notifier).since(now));
  messenger.showSnackBar(SnackBar(
    key: Key(ok ? 'reminder-set' : 'reminder-denied'),
    content: Text(ok && at != null ? l10n.mtReminderSet(formatDay(at)) : l10n.mtReminderDenied),
  ));
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.status,
    required this.late,
    required this.detail,
    required this.onDone,
    required this.reminderAt,
    required this.remindersOn,
    required this.onRemind,
  });
  final MaintenanceTask task;
  final String status;
  final bool late;
  final String? detail;
  final VoidCallback onDone;

  /// Moment du rappel (null : pas de rappel possible, ex. entretien en retard).
  final DateTime? reminderAt;
  final bool remindersOn;
  final VoidCallback onRemind;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (title, body) = task.labels(l10n);
    return Container(
      key: Key('task-${task.id}'),
      padding: const EdgeInsets.all(Space.x3 + 2),
      decoration: BoxDecoration(color: NalviumColors.surface, borderRadius: BorderRadius.circular(Corner.medium)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: NalviumColors.surfaceSubtle, borderRadius: BorderRadius.circular(14)),
                child: Icon(task.icon, color: NalviumColors.textPrimary, size: 22),
              ),
              const SizedBox(width: Space.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: NalviumText.title.copyWith(fontSize: 16.5)),
                    const SizedBox(height: 2),
                    Text(body, style: NalviumText.caption),
                    const SizedBox(height: Space.x1),
                    Text(
                      [status, ?detail].join(' · '),
                      style: NalviumText.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: late ? NalviumColors.dangerText : NalviumColors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Space.x2,
            children: [
              if (reminderAt != null)
                AnimatedSwitcher(
                  duration: motionDuration(context),
                  child: remindersOn
                      ? Padding(
                          key: Key('task-${task.id}-reminder'),
                          padding: const EdgeInsets.symmetric(horizontal: Space.x2, vertical: Space.x3),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                const WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Padding(
                                    padding: EdgeInsets.only(right: Space.x1),
                                    child: Icon(Icons.notifications_active_outlined, size: 16, color: NalviumColors.textSecondary),
                                  ),
                                ),
                                TextSpan(text: l10n.mtReminderOn(formatDay(reminderAt!))),
                              ],
                            ),
                            style: NalviumText.caption.copyWith(color: NalviumColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        )
                      : TextButton.icon(
                          key: Key('task-${task.id}-remind'),
                          onPressed: onRemind,
                          icon: const Icon(Icons.notifications_none_rounded, size: 18),
                          label: Text(l10n.mtRemind),
                          style: TextButton.styleFrom(
                            foregroundColor: NalviumColors.primaryText,
                            minimumSize: const Size(48, 44),
                            textStyle: NalviumText.button.copyWith(fontSize: 15),
                          ),
                        ),
                ),
              TextButton.icon(
                key: Key('task-${task.id}-done'),
                onPressed: onDone,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(l10n.mtDone),
                style: TextButton.styleFrom(
                  foregroundColor: NalviumColors.textPrimary,
                  minimumSize: const Size(48, 44),
                  textStyle: NalviumText.button.copyWith(fontSize: 15),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
