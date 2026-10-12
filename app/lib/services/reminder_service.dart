import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Un rappel à programmer : tout est calculé et rédigé sur le téléphone, rien n'est envoyé.
@immutable
class ScheduledReminder {
  const ScheduledReminder({required this.id, required this.at, required this.title, required this.body});
  final int id;
  final DateTime at;
  final String title;
  final String body;

  @override
  bool operator ==(Object other) =>
      other is ScheduledReminder && other.id == id && other.at == at && other.title == title && other.body == body;

  @override
  int get hashCode => Object.hash(id, at, title, body);
}

/// Notifications locales (rappels d'entretien). Les tests le remplacent par un faux, sans plugin.
abstract interface class ReminderService {
  /// Prépare le plugin SANS demander d'autorisation. [onOpen] : l'utilisateur a touché un rappel.
  /// Retourne true si l'app vient d'être ouverte par un rappel.
  Future<bool> init({required VoidCallback onOpen});

  /// Demande l'autorisation (Android 13+, iOS) : seulement après un geste explicite de l'utilisateur.
  Future<bool> requestPermission();

  /// Remplace tous les rappels programmés par [reminders].
  Future<void> replaceAll(List<ScheduledReminder> reminders, {required String channelName, required String channelDescription});

  Future<void> cancelAll();
}

/// Implémentation flutter_local_notifications. Rappels INEXACTS (pas d'alarme exacte : aucune permission
/// SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM) ; Android peut les décaler de quelques minutes.
class LocalNotificationReminderService implements ReminderService {
  LocalNotificationReminderService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();
  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;
  VoidCallback? _onOpen;

  static const _channelId = 'maintenance';

  Future<void> _ensureInit() async {
    if (_ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Aucune demande au lancement : l'autorisation est demandée au moment où l'utilisateur active un rappel.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (_) => _onOpen?.call(),
    );
    _ready = true;
  }

  @override
  Future<bool> init({required VoidCallback onOpen}) async {
    _onOpen = onOpen;
    try {
      await _ensureInit();
      final launch = await _plugin.getNotificationAppLaunchDetails();
      return launch?.didNotificationLaunchApp ?? false;
    } catch (e) {
      debugPrint('[Nalvium] rappels indisponibles : $e');
      return false;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      await _ensureInit();
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) return await android.requestNotificationsPermission() ?? false;
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) return await ios.requestPermissions(alert: true, sound: true) ?? false;
      return false;
    } catch (e) {
      debugPrint('[Nalvium] autorisation des rappels : $e');
      return false;
    }
  }

  @override
  Future<void> replaceAll(
    List<ScheduledReminder> reminders, {
    required String channelName,
    required String channelDescription,
  }) async {
    try {
      await _ensureInit();
      await _plugin.cancelAllPendingNotifications();
      final details = NotificationDetails(
        android: AndroidNotificationDetails(_channelId, channelName, channelDescription: channelDescription),
        iOS: const DarwinNotificationDetails(),
      );
      for (final r in reminders) {
        await _plugin.zonedSchedule(
          id: r.id,
          title: r.title,
          body: r.body,
          // Instant absolu (UTC) calculé depuis l'heure locale du téléphone : pas de base de fuseaux à embarquer.
          scheduledDate: tz.TZDateTime.from(r.at, tz.UTC),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'house',
        );
      }
    } catch (e) {
      debugPrint('[Nalvium] programmation des rappels : $e');
    }
  }

  @override
  Future<void> cancelAll() async {
    try {
      await _ensureInit();
      await _plugin.cancelAllPendingNotifications();
    } catch (e) {
      debugPrint('[Nalvium] annulation des rappels : $e');
    }
  }
}
