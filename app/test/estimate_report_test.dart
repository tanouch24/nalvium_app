import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/core/network/api_exceptions.dart';
import 'package:nalvium/domain/diagnosis.dart';
import 'package:nalvium/domain/estimate.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

const _estimate = {
  'diy_feasibility': 8,
  'difficulty': 'easy',
  'duration_minutes': 20,
  'diy_cost_min': 5,
  'diy_cost_max': 12,
  'pro_cost_min': 120,
  'pro_cost_max': 180,
  'parts': [
    {'name': 'Joint fibre 15×21', 'approx_eur': 2},
  ],
};

Finder k(String key) => find.byKey(Key(key));

Future<FakeSessionsRepository> open(WidgetTester tester, {NextActionType action = NextActionType.askQuestion, Map<String, dynamic>? estimate = _estimate, String status = 'active', double textScale = 1.0, Size size = const Size(1080, 3600)}) async {
  final repo = FakeSessionsRepository(
    stored: sessionState(action: action, message: 'Où coule l\'eau ?', choices: const ['Oui', 'Non'], estimate: estimate, status: status),
  );
  await pumpApp(tester, repo: repo, location: '/session/s1', textScale: textScale, size: size);
  return repo;
}

void main() {
  group('modèle', () {
    test('lecture tolérante et économies', () {
      final e = RepairEstimate.maybe(_estimate)!;
      expect(e.diyMid, 9);
      expect(e.proMid, 150);
      expect(e.savings, 141);
      expect(RepairEstimate.maybe(null), isNull);
      expect(RepairEstimate.maybe({'difficulty': 'easy'}), isNull); // forme invalide : ignorée, jamais d'erreur
      expect(RepairEstimate.maybe({..._estimate, 'pro_cost_min': null, 'pro_cost_max': null})!.savings, isNull);
    });
    test('formats', () {
      expect(formatEuros(5, 12), '5–12 €');
      expect(formatEuros(8, 9), '~9 €');
      expect(formatEuros(null, 150), '~150 €');
      expect(formatEuros(null, null), '—');
      expect(formatDuration(20), '20 min');
      expect(formatDuration(90), '1 h 30');
      expect(formatDuration(120), '2 h');
    });
  });

  group('carte résultat', () {
    testWidgets('affiche faisabilité, durée, coûts, pièces et la mention « pas un devis »', (tester) async {
      await open(tester);
      await tester.scrollUntilVisible(k('estimate-card'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('8/10', findRichText: true), findsOneWidget);
      expect(find.text('20 min'), findsOneWidget);
      expect(find.text('Facile'), findsOneWidget);
      expect(find.text('5–12 €'), findsOneWidget);
      expect(find.text('120–180 €'), findsOneWidget);
      expect(find.text('Joint fibre 15×21'), findsOneWidget);
      expect(find.textContaining('pas un devis'), findsOneWidget);
    });

    testWidgets('aucune carte sans estimation', (tester) async {
      await open(tester, estimate: null);
      expect(k('estimate-card'), findsNothing);
    });

    testWidgets('jamais de carte sur un arrêt de sécurité', (tester) async {
      await open(tester, action: NextActionType.safetyStop);
      expect(k('estimate-card'), findsNothing);
    });

    testWidgets('DIY déconseillé : pas de prix « vous-même » ni de liste de pièces', (tester) async {
      await open(tester, estimate: {..._estimate, 'diy_feasibility': 2});
      await tester.scrollUntilVisible(k('estimate-card'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('À confier à un professionnel'), findsOneWidget);
      expect(find.text('Joint fibre 15×21'), findsNothing);
    });

    testWidgets('résolu : montant économisé affiché', (tester) async {
      await open(tester, action: NextActionType.resolved, status: 'resolved');
      expect(find.text('Vous avez économisé environ 141 €'), findsOneWidget);
    });

    testWidgets('récapitulatif : carte et signalement', (tester) async {
      final repo = FakeSessionsRepository(stored: sessionState(action: NextActionType.resolved, status: 'resolved', estimate: _estimate));
      await pumpApp(tester, repo: repo, location: '/session/s1/summary');
      await tester.scrollUntilVisible(k('report-result'), 200, scrollable: find.byType(Scrollable).first);
      expect(k('estimate-card'), findsOneWidget);
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('320 dp × $scale : sans overflow', (tester) async {
        await open(tester, textScale: scale, size: const Size(960, 2400));
        await tester.scrollUntilVisible(k('estimate-card'), 200, scrollable: find.byType(Scrollable).first);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('signaler ce résultat', () {
    testWidgets('choisir une raison, préciser, envoyer : remerciement', (tester) async {
      final repo = await open(tester);
      await tester.scrollUntilVisible(k('report-result'), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(k('report-result'));
      await tester.pumpAndSettle();
      expect(k('report-sheet-title'), findsOneWidget);
      await tester.tap(k('report-dangerous'));
      await tester.pump();
      await tester.enterText(k('report-details'), 'Il faut couper le courant');
      await tester.tap(k('report-send'));
      await tester.pumpAndSettle();
      expect(repo.reports.single, ('s1', 'dangerous', 'Il faut couper le courant'));
      expect(k('report-thanks'), findsOneWidget);
    });

    testWidgets('sans raison, rien n\'est envoyé ; échec réseau : message honnête', (tester) async {
      final repo = await open(tester);
      repo.reportError = const ApiNetworkException();
      await tester.scrollUntilVisible(k('report-result'), 200, scrollable: find.byType(Scrollable).first);
      await tester.tap(k('report-result'));
      await tester.pumpAndSettle();
      await tester.tap(k('report-send'));
      await tester.pumpAndSettle();
      expect(k('report-sheet-title'), findsOneWidget); // bouton inactif sans raison
      await tester.tap(k('report-wrong'));
      await tester.pump();
      await tester.tap(k('report-send'));
      await tester.pumpAndSettle();
      expect(repo.reports, isEmpty);
      expect(k('report-failed'), findsOneWidget);
    });
  });

  testWidgets('limite quotidienne : message clair à la création d\'un diagnostic', (tester) async {
    final repo = FakeSessionsRepository(turns: [const ApiHttpException(429, 'daily_limit')]);
    await pumpApp(tester, repo: repo, location: '/describe');
    await tester.enterText(k('describe-field'), 'Mon robinet goutte');
    await tester.pump();
    await tester.tap(k('describe-continue'));
    await tester.pumpAndSettle();
    expect(find.text('Beaucoup de diagnostics aujourd\'hui'), findsOneWidget);
  });
}
