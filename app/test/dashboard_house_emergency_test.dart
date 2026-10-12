import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/domain/estimate.dart';
import 'package:nalvium/domain/home_profile.dart';
import 'package:nalvium/domain/session.dart';
import 'package:nalvium/features/home/dashboard.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

Finder k(String key) => find.byKey(Key(key));

/// Les listes sont paresseuses : on fait défiler jusqu'à l'élément.
Future<void> show(WidgetTester t, String key) async {
  await t.scrollUntilVisible(k(key), 150, scrollable: find.byType(Scrollable).hitTestable().first);
  await t.pumpAndSettle();
}

Future<void> tapK(WidgetTester t, String key) async {
  await show(t, key);
  await t.pumpAndSettle();
  await t.tap(k(key));
  await t.pumpAndSettle();
}

const _est = {
  'diy_feasibility': 8, 'difficulty': 'easy', 'diy_cost_min': 5, 'diy_cost_max': 12, 'pro_cost_min': 120, 'pro_cost_max': 180,
};

SessionSummary _s(String status, Map<String, dynamic>? est) => SessionSummary(
  id: 'x$status${est.hashCode}', status: status, currentState: 'RESOLVED', updatedAt: DateTime(2026, 10, 1),
  estimate: RepairEstimate.maybe(est),
);

Map<String, Object> _profile(HomeProfile p) => {'nalvium.home_profile': p.toJsonString()};

void main() {
  test('économies : seulement les réparations résolues faisables soi-même', () {
    final r = savingsOf([
      _s('resolved', _est),
      _s('resolved', {..._est, 'diy_feasibility': 2}), // à confier à un pro : pas une économie
      _s('active', _est),
      _s('resolved', null),
    ]);
    expect((r.total, r.repairs), (141, 1));
  });

  testWidgets('accueil : suivi, économies réelles, prochain entretien, urgence', (tester) async {
    final repo = FakeSessionsRepository(sessions: [_s('resolved', _est)]);
    await pumpApp(tester, repo: repo, prefs: _profile(const HomeProfile(heating: 'gas')));
    await show(tester, 'dash-follow-up');
    expect(find.text('À compléter'), findsOneWidget);
    expect(find.text('Ajoutez vos points vitaux dans Ma maison'), findsOneWidget);
    expect(find.text('141 €'), findsOneWidget);
    expect(find.text('1 réparation faite vous-même'), findsOneWidget);
    expect(find.text('Entretien de la chaudière'), findsOneWidget); // obligatoire, jamais noté : en tête
    expect(find.text('À planifier'), findsOneWidget);
  });

  testWidgets('accueil sans historique : aucune somme inventée', (tester) async {
    await pumpApp(tester);
    await show(tester, 'dash-savings');
    expect(find.textContaining('Vos économies s\'afficheront ici'), findsOneWidget);
    expect(find.textContaining(' €'), findsNothing);
  });

  testWidgets('Ma maison : points vitaux et entretiens ; « C\'est fait » met à jour l\'échéance', (tester) async {
    await pumpApp(tester, prefs: _profile(const HomeProfile(hotWater: 'electric_tank')));
    await tester.tap(k('nav-house'));
    await tester.pumpAndSettle();
    await show(tester, 'task-water_heater');
    expect(k('vital-waterValve'), findsOneWidget);
    expect(k('task-boiler'), findsNothing); // pas de chaudière déclarée
    await tapK(tester, 'task-vmc-done');
    expect(find.textContaining('Dans 180 jours'), findsOneWidget);
    // Rappels désactivés par défaut : on ne promet pas de rappel.
    expect(find.text('Entretien noté.'), findsOneWidget);
  });

  testWidgets('urgence : consignes fixes, numéros, composeur ouvert sans appel automatique', (tester) async {
    final dialed = <String>[];
    await pumpApp(tester, dialer: (n) async => dialed.add(n));
    await tapK(tester, 'open-emergency');
    expect(k('em-title'), findsOneWidget);
    expect(find.text('Coupez l\'eau à la vanne d\'arrêt.'), findsOneWidget);
    await show(tester, 'em-gas');
    expect(find.textContaining('N\'actionnez aucun interrupteur'), findsOneWidget);
    await tapK(tester, 'em-call-gas');
    await tapK(tester, 'em-call-112');
    expect(dialed, ['0800473333', '112']);
  });

  testWidgets('urgence : pas de composeur (tablette) → le numéro à composer est affiché', (tester) async {
    await pumpApp(tester, dialer: (_) async => throw PlatformException(code: 'ACTIVITY_NOT_FOUND'));
    await tapK(tester, 'open-emergency');
    await tapK(tester, 'em-call-gas');
    expect(k('em-no-dialer'), findsOneWidget);
    expect(find.text('Appel impossible depuis cet appareil'), findsOneWidget);
    expect(find.text('0 800 47 33 33'), findsOneWidget);
    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();
    expect(k('em-no-dialer'), findsNothing);
    await tapK(tester, 'em-call-112');
    expect(find.text('112'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('320 dp × $scale : accueil, Ma maison, urgence sans overflow', (tester) async {
      await pumpApp(tester, size: const Size(960, 2400), textScale: scale, prefs: _profile(const HomeProfile(heating: 'gas', hotWater: 'boiler')));
      await tapK(tester, 'open-emergency');
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(k('nav-house'));
      await tester.pumpAndSettle();
      await show(tester, 'task-boiler');
      expect(tester.takeException(), isNull);
    });
  }
}
