import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/domain/home_profile.dart';
import 'package:nalvium/features/house/house_screen.dart';
import 'package:nalvium/features/house/maintenance_reminders.dart';
import 'package:nalvium/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/pump_app.dart';

Finder k(String key) => find.byKey(Key(key));

Future<void> show(WidgetTester t, String key) async {
  await t.scrollUntilVisible(k(key), 150, scrollable: find.byType(Scrollable).hitTestable().first);
  await t.pumpAndSettle();
}

Future<void> tapK(WidgetTester t, String key) async {
  await show(t, key);
  await t.tap(k(key));
  await t.pumpAndSettle();
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

Map<String, Object> _profile(HomeProfile p) => {'nalvium.home_profile': p.toJsonString()};

Future<void> openHouse(WidgetTester tester) async {
  await tester.tap(k('nav-house'));
  await tester.pumpAndSettle();
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('fr'));

  group('calcul des rappels', () {
    final now = DateTime(2026, 10, 12, 15, 30);

    test('vers 10 h le jour prévu', () {
      final p = HomeProfile(maintenanceDone: {'vmc': DateTime(2026, 9, 1, 18)});
      expect(reminderDateFor(MaintenanceTask.vmc, p, now, since: now), DateTime(2027, 2, 28, 10));
    });

    test('en retard : pas de rappel (déjà signalé dans Ma maison, pas de relance chaque matin)', () {
      final p = HomeProfile(maintenanceDone: {'smoke_alarm': DateTime(2026, 6, 1)});
      expect(reminderDateFor(MaintenanceTask.smokeAlarm, p, now, since: now), isNull);
    });

    test('jamais noté (« à planifier ») : une semaine après l\'activation, vers 10 h', () {
      expect(reminderDateFor(MaintenanceTask.boiler, const HomeProfile(), now, since: now), DateTime(2026, 10, 19, 10));
      // Ce moment passé, plus de rappel.
      expect(reminderDateFor(MaintenanceTask.boiler, const HomeProfile(), now, since: DateTime(2026, 9, 1)), isNull);
    });

    test('plan : un rappel par entretien, identifiants stables et distincts, textes en français', () {
      const p = HomeProfile(heating: 'gas', hotWater: 'electric_tank');
      final plan = maintenanceReminderPlan(p, now, l10n, since: now);
      expect(plan.map((r) => r.id).toSet().length, plan.length);
      expect(plan.length, MaintenanceTask.forProfile(p).length);
      expect(plan.first.title, 'Entretien de la chaudière');
      expect(plan.first.body, contains('Ma maison'));
      expect(plan.every((r) => r.at.hour == kReminderHour), isTrue);
      expect(reminderIdFor('boiler'), isNot(reminderIdFor('vmc')));
    });
  });

  group('autorisation contextuelle', () {
    testWidgets('au lancement : aucune demande d\'autorisation, aucun rappel programmé', (tester) async {
      final fake = FakeReminderService();
      await pumpApp(tester, reminders: fake);
      expect(fake.permissionRequests, 0);
      expect(fake.inits, 0);
      expect(fake.scheduled, isEmpty);
    });

    testWidgets('« Me le rappeler » : autorisation demandée à ce moment-là, rappel programmé vers 10 h', (tester) async {
      final fake = FakeReminderService();
      final done = DateTime.now().subtract(const Duration(days: 20));
      await pumpApp(tester, reminders: fake, prefs: _profile(HomeProfile(maintenanceDone: {'vmc': done})));
      await openHouse(tester);
      await tapK(tester, 'task-vmc-remind');
      expect(fake.permissionRequests, 1);
      expect(k('reminder-set'), findsOneWidget);
      final vmc = fake.scheduled.firstWhere((r) => r.id == reminderIdFor('vmc'));
      expect(vmc.at, _day(done.add(const Duration(days: 180))).add(const Duration(hours: 10)));
      expect(vmc.title, 'Bouches de ventilation (VMC)');
      // Le bouton devient l'état « Rappel le … ».
      expect(k('task-vmc-remind'), findsNothing);
      expect(k('task-vmc-reminder'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('nalvium.maintenance_reminders'), isTrue);
    });

    testWidgets('autorisation refusée : message clair, rien d\'activé', (tester) async {
      final fake = FakeReminderService(grant: false);
      await pumpApp(tester, reminders: fake);
      await openHouse(tester);
      await tapK(tester, 'task-vmc-remind');
      expect(k('reminder-denied'), findsOneWidget);
      expect(fake.scheduled, isEmpty);
      expect(k('task-vmc-remind'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('nalvium.maintenance_reminders'), isNull);
    });

    testWidgets('entretien en retard : pas de « Me le rappeler »', (tester) async {
      await pumpApp(tester, prefs: _profile(HomeProfile(maintenanceDone: {'smoke_alarm': DateTime.now().subtract(const Duration(days: 200))})));
      await openHouse(tester);
      await show(tester, 'task-smoke_alarm');
      expect(k('task-smoke_alarm-remind'), findsNothing);
      expect(k('task-smoke_alarm-done'), findsOneWidget);
    });
  });

  group('Réglages › Rappels d\'entretien', () {
    testWidgets('activer demande l\'autorisation ; désactiver annule tous les rappels', (tester) async {
      final fake = FakeReminderService();
      await pumpApp(tester, reminders: fake, location: '/settings');
      expect(fake.permissionRequests, 0);
      await tapK(tester, 'st-reminders');
      expect(fake.permissionRequests, 1);
      expect(fake.scheduled, isNotEmpty);
      expect(tester.widget<Switch>(k('st-reminders')).value, isTrue);
      await tapK(tester, 'st-reminders');
      expect(fake.cancels, 1);
      expect(fake.scheduled, isEmpty);
      expect(tester.widget<Switch>(k('st-reminders')).value, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('nalvium.maintenance_reminders'), isFalse);
    });

    testWidgets('refus : l\'interrupteur reste désactivé', (tester) async {
      final fake = FakeReminderService(grant: false);
      await pumpApp(tester, reminders: fake, location: '/settings');
      await tapK(tester, 'st-reminders');
      expect(tester.widget<Switch>(k('st-reminders')).value, isFalse);
      expect(k('reminder-denied'), findsOneWidget);
    });
  });

  group('rappels activés', () {
    final enabled = {'nalvium.maintenance_reminders': true};

    testWidgets('au lancement : resynchronisés sans redemander l\'autorisation', (tester) async {
      final fake = FakeReminderService();
      await pumpApp(tester, reminders: fake, prefs: enabled);
      expect(fake.inits, 1);
      expect(fake.permissionRequests, 0);
      expect(fake.scheduled, isNotEmpty);
    });

    testWidgets('« C\'est fait » reprogramme le rappel à la nouvelle échéance', (tester) async {
      final fake = FakeReminderService();
      await pumpApp(tester, reminders: fake, prefs: enabled);
      await openHouse(tester);
      await tapK(tester, 'task-vmc-done');
      expect(find.text('Entretien noté. Nalvium vous le rappellera.'), findsOneWidget);
      final vmc = fake.scheduled.firstWhere((r) => r.id == reminderIdFor('vmc'));
      expect(vmc.at, _day(DateTime.now().add(const Duration(days: 180))).add(const Duration(hours: 10)));
    });

    testWidgets('app ouverte en touchant un rappel : Ma maison s\'affiche', (tester) async {
      final fake = FakeReminderService(launchedFromReminder: true);
      await pumpApp(tester, reminders: fake, prefs: enabled);
      expect(find.byType(HouseScreen).hitTestable(), findsOneWidget);
    });

    testWidgets('rappel touché pendant l\'utilisation : Ma maison s\'affiche', (tester) async {
      final fake = FakeReminderService();
      await pumpApp(tester, reminders: fake, prefs: enabled);
      expect(find.byType(HouseScreen).hitTestable(), findsNothing);
      fake.onOpen!();
      await tester.pumpAndSettle();
      expect(find.byType(HouseScreen).hitTestable(), findsOneWidget);
    });
  });

  testWidgets('suivi de la maison : noter un entretien fait monter l\'anneau de l\'accueil', (tester) async {
    const p = HomeProfile(housing: 'house');
    await pumpApp(tester, prefs: _profile(p));
    await show(tester, 'dash-follow-up');
    final before = homeFollowUpScore(p, DateTime.now());
    expect(find.descendant(of: k('dash-follow-up'), matching: find.text('$before')), findsOneWidget);
    await openHouse(tester);
    await tapK(tester, 'task-vmc-done');
    await tester.tap(k('nav-home'));
    await tester.pumpAndSettle();
    await show(tester, 'dash-follow-up');
    final after = homeFollowUpScore(p.copyWith(maintenanceDone: {'vmc': DateTime.now()}), DateTime.now());
    expect(after, greaterThan(before));
    expect(find.descendant(of: k('dash-follow-up'), matching: find.text('$after')), findsOneWidget);
  });
}
