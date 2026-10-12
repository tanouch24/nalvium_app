import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/home_profile.dart';
import '../../l10n/app_localizations.dart';
import '../../services/providers.dart';
import '../../services/reminder_service.dart';
import 'maintenance_section.dart';

/// Heure locale des rappels d'entretien (le jour prévu).
const kReminderHour = 10;

/// Identifiants stables des notifications, un par entretien.
const _taskIds = ['boiler', 'radiators', 'heat_pump', 'water_heater', 'vmc', 'smoke_alarm'];

int reminderIdFor(String taskId) => 100 + _taskIds.indexOf(taskId);

/// Moment du rappel d'un entretien : vers 10 h le jour prévu. Entretien jamais noté (« à planifier ») : une
/// semaine après l'activation des rappels ([since]). Null si ce moment est déjà passé (un retard reste visible
/// dans Ma maison : on ne relance pas chaque matin).
DateTime? reminderDateFor(MaintenanceTask t, HomeProfile p, DateTime now, {required DateTime since}) {
  final base = t.dueDate(p) ?? since.add(const Duration(days: 7));
  final at = DateTime(base.year, base.month, base.day, kReminderHour);
  return at.isAfter(now) ? at : null;
}

/// Rappels à programmer pour le profil (tout reste sur le téléphone).
List<ScheduledReminder> maintenanceReminderPlan(
  HomeProfile p,
  DateTime now,
  AppLocalizations l10n, {
  required DateTime since,
}) => [
  for (final t in MaintenanceTask.forProfile(p))
    if (reminderDateFor(t, p, now, since: since) case final at?)
      ScheduledReminder(id: reminderIdFor(t.id), at: at, title: t.labels(l10n).$1, body: l10n.notifBody),
];

/// Service de notifications locales. Surchargé en test par un faux.
final reminderServiceProvider = Provider<ReminderService>((ref) => LocalNotificationReminderService());

/// Rappels d'entretien activés ? Jamais d'autorisation demandée au lancement : seulement via « Me le rappeler »
/// ou le réglage « Rappels d'entretien ».
class MaintenanceReminders extends Notifier<bool> {
  @override
  bool build() => ref.read(localStoreProvider).maintenanceReminders;

  VoidCallback? _onOpen;

  AppLocalizations get _l10n => lookupAppLocalizations(const Locale('fr'));

  /// Date de référence des entretiens « à planifier » (activation des rappels, ou maintenant pour un aperçu).
  DateTime since(DateTime now) => ref.read(localStoreProvider).maintenanceRemindersSince ?? now;

  /// Demande l'autorisation, puis programme les rappels. False si l'utilisateur a refusé.
  Future<bool> enable() async {
    final granted = await ref.read(reminderServiceProvider).requestPermission();
    if (!granted) return false;
    await ref.read(reminderServiceProvider).init(onOpen: () => _onOpen?.call());
    final store = ref.read(localStoreProvider);
    await store.setMaintenanceReminders(true, since: store.maintenanceRemindersSince ?? ref.read(clockProvider)());
    state = true;
    await sync();
    return true;
  }

  /// Désactive et annule tous les rappels programmés.
  Future<void> disable() async {
    await ref.read(localStoreProvider).setMaintenanceReminders(false);
    state = false;
    await ref.read(reminderServiceProvider).cancelAll();
  }

  /// Reprogramme d'après le profil actuel (entretien noté, profil complété…).
  Future<void> sync() async {
    if (!state) return;
    final now = ref.read(clockProvider)();
    final l10n = _l10n;
    await ref.read(reminderServiceProvider).replaceAll(
      maintenanceReminderPlan(ref.read(homeProfileProvider), now, l10n, since: since(now)),
      channelName: l10n.notifChannelName,
      channelDescription: l10n.notifChannelDescription,
    );
  }

  /// Au lancement (rappels déjà activés seulement) : prépare le plugin, resynchronise, et ouvre Ma maison si
  /// l'app a été lancée en touchant un rappel.
  Future<void> start({required VoidCallback onOpen}) async {
    _onOpen = onOpen;
    if (!state) return;
    final launched = await ref.read(reminderServiceProvider).init(onOpen: () => _onOpen?.call());
    await sync();
    if (launched) onOpen();
  }
}

final maintenanceRemindersProvider = NotifierProvider<MaintenanceReminders, bool>(MaintenanceReminders.new);
