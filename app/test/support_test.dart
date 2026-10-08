import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/domain/diagnosis.dart';
import 'package:nalvium/services/tips_service.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

Finder k(String key) => find.byKey(Key(key));

Future<void> tapK(WidgetTester t, String key) async {
  await t.scrollUntilVisible(k(key), 150, scrollable: find.byType(Scrollable).hitTestable().last);
  await t.pumpAndSettle();
  await t.tap(k(key));
  await t.pumpAndSettle();
}

Future<FakeTipsService> openResolved(WidgetTester t, {FakeTipsService? tips}) async {
  final f = tips ?? FakeTipsService();
  await pumpApp(
    t,
    tips: f,
    location: '/session/s1',
    repo: FakeSessionsRepository(stored: sessionState(action: NextActionType.resolved, status: 'resolved', message: 'C\'est réglé.')),
  );
  return f;
}

void main() {
  testWidgets('après une réparation : carte « Soutenir », 3 montants du store, « Deux cafés » présélectionné', (tester) async {
    final tips = await openResolved(tester);
    await tapK(tester, 'support-open');
    expect(k('support-title'), findsOneWidget);
    expect(find.text('2,99 €'), findsOneWidget);
    expect(find.text('9,99 €'), findsOneWidget);
    expect(find.textContaining('sans contrepartie'), findsOneWidget);
    await tester.tap(k('support-pay'));
    await tester.pumpAndSettle();
    expect(tips.bought, ['nalvium.tip.two_coffees']);
    expect(k('support-thanks'), findsOneWidget);
  });

  testWidgets('choisir un autre montant ; « Pas maintenant » ne débite rien', (tester) async {
    final tips = await openResolved(tester);
    await tapK(tester, 'support-open');
    await tester.tap(k('support-later'));
    await tester.pumpAndSettle();
    expect(tips.bought, isEmpty);
    await tapK(tester, 'support-open');
    await tester.tap(k('tip-nalvium.tip.meal'));
    await tester.pump();
    await tester.tap(k('support-pay'));
    await tester.pumpAndSettle();
    expect(tips.bought, ['nalvium.tip.meal']);
  });

  testWidgets('paiement refusé : message honnête', (tester) async {
    await openResolved(tester, tips: FakeTipsService(outcome: TipOutcome.failed));
    await tapK(tester, 'support-open');
    await tester.tap(k('support-pay'));
    await tester.pumpAndSettle();
    expect(k('support-failed'), findsOneWidget);
  });

  testWidgets('store indisponible : aucun bouton de paiement', (tester) async {
    await pumpApp(tester, tips: FakeTipsService(available: false), location: '/settings');
    await tapK(tester, 'st-support');
    expect(k('support-unavailable'), findsOneWidget);
    expect(k('support-pay'), findsNothing);
  });

  testWidgets('320 dp × 2 : feuille de soutien sans overflow', (tester) async {
    await pumpApp(tester, location: '/settings', size: const Size(960, 2400), textScale: 2.0);
    await tapK(tester, 'st-support');
    expect(tester.takeException(), isNull);
  });
}
