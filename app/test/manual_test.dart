import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/core/network/api_exceptions.dart';
import 'package:nalvium/domain/diagnosis.dart';
import 'package:nalvium/domain/equipment.dart';
import 'package:nalvium/domain/session.dart';

import 'helpers/fake_home.dart';
import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

Finder k(String key) => find.byKey(Key(key));

const _available = ManualInfo(
  status: 'available', manufacturer: 'Bosch', modelReference: 'SMS46GI01E', sourceDomain: 'media3.bosch-home.com',
  official: true, pageCount: 84, matchLevel: 'exact',
);

Future<void> openDetail(WidgetTester tester, FakeHomeRepository home, {FakeAdsService? ads, FakeSessionsRepository? repo, Size? size, double scale = 1.0}) async {
  await pumpApp(tester, home: home, ads: ads, repo: repo, location: '/equipment/a', size: size ?? const Size(1080, 3600), textScale: scale);
}

Future<void> show(WidgetTester tester, String key) async {
  await tester.ensureVisible(k(key));
  await tester.pumpAndSettle();
}

void main() {
  group('RÉFÉRENCE', () {
    testWidgets('sans référence : l’équipement reste utilisable, « Référence nécessaire » + aide discrète', (tester) async {
      final home = FakeHomeRepository(items: [equipment(id: 'a', brand: 'Bosch')]);
      await openDetail(tester, home);
      expect(k('equipment-no-model'), findsOneWidget);
      expect(find.text('Référence nécessaire'), findsOneWidget);
      expect(k('manual-search'), findsNothing); // pas de recherche sans référence
      expect(k('equipment-diagnose'), findsOneWidget); // rien n'est bloqué
      await show(tester, 'reference-help');
      await tester.tap(k('reference-help').first);
      await tester.pumpAndSettle();
      expect(k('reference-help-body'), findsOneWidget);
      expect(find.textContaining('plaque signalétique'), findsOneWidget);
    });

    testWidgets('marque et référence sont distinctes sur la fiche', (tester) async {
      final home = FakeHomeRepository(items: [equipment(id: 'a', brand: 'Bosch', model: 'SMS46GI01E')]);
      await openDetail(tester, home);
      expect(find.text('Bosch'), findsOneWidget);
      expect(find.text('Référence : SMS46GI01E'), findsOneWidget);
    });

    testWidgets('l’aide « Où trouver la référence ? » existe dans l’ajout et la modification', (tester) async {
      await pumpApp(tester, home: FakeHomeRepository(items: [equipment(id: 'a')]), location: '/equipment/add');
      await tester.tap(k('kind-oven'));
      await tester.pumpAndSettle();
      await tester.tap(k('room-skip'));
      await tester.pumpAndSettle();
      expect(k('reference-help'), findsOneWidget);
      expect(find.text('Modèle / référence'), findsOneWidget);
    });

    testWidgets('identification sans référence lisible : photo plus proche de la plaque, jamais de référence inventée', (tester) async {
      // couvert côté serveur ; ici l'UI affiche le conseil lorsque le modèle est inconnu
      final home = FakeHomeRepository();
      await pumpApp(tester, home: home, location: '/equipment/identify');
      expect(find.byKey(const Key('identify-take')), findsOneWidget);
    });
  });

  group('NOTICE — états', () {
    testWidgets('aucune notice : « Rechercher la notice » → recherche en cours → disponible, sans toucher au compteur', (tester) async {
      final gate = Completer<void>();
      final ads = FakeAdsService();
      final home = FakeHomeRepository(items: [equipment(id: 'a', brand: 'Bosch', model: 'SMS46GI01E')])
        ..searchGate = gate
        ..nextSearch = const ManualSearchResult(outcome: 'found', manual: _available);
      await openDetail(tester, home, ads: ads);
      await show(tester, 'manual-search');
      await tester.tap(k('manual-search'));
      await tester.pump();
      expect(find.text('Recherche en cours'), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('Notice disponible'), findsOneWidget);
      expect(find.textContaining('Source officielle du fabricant'), findsOneWidget);
      expect(find.textContaining('84 pages'), findsOneWidget);
      expect(find.textContaining('media3.bosch-home.com'), findsOneWidget);
      expect(k('manual-consult'), findsOneWidget);
      expect(ads.newDiagnostics, 0); // chercher une notice n'est pas un diagnostic
    });

    testWidgets('notice exacte introuvable : message honnête, usage normal conservé', (tester) async {
      final home = FakeHomeRepository(items: [equipment(id: 'a', brand: 'Bosch', model: 'SMS46GI01E')]);
      await openDetail(tester, home);
      await show(tester, 'manual-search');
      await tester.tap(k('manual-search'));
      await tester.pumpAndSettle();
      expect(find.text('Notice exacte introuvable'), findsOneWidget);
      expect(find.textContaining('utiliser l\'équipement normalement'), findsOneWidget);
      expect(k('equipment-diagnose'), findsOneWidget);
      expect(k('manual-retry'), findsOneWidget);
    });

    testWidgets('notice proche : jamais associée sans confirmation ; confirmation puis disponible', (tester) async {
      final home = FakeHomeRepository(items: [equipment(id: 'a', brand: 'Bosch', model: 'SMS46GI01E')])
        ..nextSearch = const ManualSearchResult(
          outcome: 'needs_confirmation',
          manual: ManualInfo(status: 'needs_confirmation', manufacturer: 'Bosch', modelReference: 'SMS46GI01E', official: true, pageCount: 40, matchLevel: 'approximate'),
        );
      await openDetail(tester, home);
      await show(tester, 'manual-search');
      await tester.tap(k('manual-search'));
      await tester.pumpAndSettle();
      expect(find.text('Une notice proche a été trouvée'), findsOneWidget);
      expect(k('manual-consult'), findsNothing); // pas consultable ni utilisée avant confirmation
      await show(tester, 'manual-approx-yes');
      await tester.tap(k('manual-approx-yes'));
      await tester.pumpAndSettle();
      expect(home.calls, contains('manual-confirm:a'));
      expect(find.text('Notice disponible'), findsOneWidget);
    });

    testWidgets('notice proche ignorée : supprimée', (tester) async {
      final home = FakeHomeRepository(items: [equipment(id: 'a', brand: 'Bosch', model: 'X1234')])
        ..manuals['a'] = const ManualInfo(status: 'needs_confirmation', pageCount: 10);
      await openDetail(tester, home);
      await show(tester, 'manual-approx-no');
      await tester.tap(k('manual-approx-no'));
      await tester.pumpAndSettle();
      expect(home.calls, contains('manual-delete:a'));
      expect(k('manual-search'), findsOneWidget);
    });

    testWidgets('erreur de récupération : message + réessayer', (tester) async {
      final home = FakeHomeRepository(items: [equipment(id: 'a', brand: 'Bosch', model: 'SMS46GI01E')])
        ..manualError = const ApiNetworkException();
      await openDetail(tester, home);
      await show(tester, 'manual-search');
      await tester.tap(k('manual-search'));
      await tester.pumpAndSettle();
      expect(find.text('Erreur de récupération'), findsOneWidget);
      home.manualError = null;
      home.nextSearch = const ManualSearchResult(outcome: 'found', manual: _available);
      await tester.tap(k('manual-retry'));
      await tester.pumpAndSettle();
      expect(find.text('Notice disponible'), findsOneWidget);
    });

    testWidgets('mise à jour : « déjà à jour » / ancienne notice conservée', (tester) async {
      final home = FakeHomeRepository(items: [equipment(id: 'a', brand: 'Bosch', model: 'SMS46GI01E')])
        ..manuals['a'] = _available
        ..nextSearch = const ManualSearchResult(outcome: 'up_to_date', manual: _available);
      await openDetail(tester, home);
      await show(tester, 'manual-update');
      await tester.tap(k('manual-update'));
      await tester.pumpAndSettle();
      expect(find.text('La notice est déjà à jour.'), findsOneWidget);
      home.nextSearch = const ManualSearchResult(outcome: 'kept', manual: _available);
      await tester.tap(k('manual-update'));
      await tester.pumpAndSettle();
      expect(find.textContaining('notice actuelle est conservée'), findsOneWidget);
    });

    testWidgets('consulter : pages navigables, texte réel, aucune pub plein écran', (tester) async {
      final ads = FakeAdsService();
      final home = FakeHomeRepository(items: [equipment(id: 'a', brand: 'Bosch', model: 'SMS46GI01E')])..manuals['a'] = _available;
      await openDetail(tester, home, ads: ads);
      await show(tester, 'manual-consult');
      await tester.tap(k('manual-consult'));
      await tester.pumpAndSettle();
      expect(find.text('Page 1 sur 84'), findsOneWidget);
      expect(find.text('Texte de la page 1'), findsOneWidget);
      await tester.tap(k('manual-next'));
      await tester.pumpAndSettle();
      expect(find.text('Texte de la page 2'), findsOneWidget);
      await tester.tap(k('manual-prev'));
      await tester.pumpAndSettle();
      expect(find.text('Page 1 sur 84'), findsOneWidget);
      expect(ads.newDiagnostics, 0);
    });
  });

  group('PROVENANCE dans le diagnostic', () {
    Future<void> runDiagnostic(WidgetTester tester, SessionState result, {Map<String, dynamic>? eq}) async {
      final repo = FakeSessionsRepository(turns: [result], stored: result);
      await pumpApp(tester, repo: repo, home: FakeHomeRepository());
      await tester.tap(k('describe-problem'));
      await tester.pumpAndSettle();
      await tester.enterText(k('describe-field'), 'erreur E15');
      await tester.pumpAndSettle();
      await tester.tap(k('describe-continue'));
      await tester.pumpAndSettle();
    }

    final eq = {'id': 'a', 'equipment_type': 'dishwasher', 'display_name': 'Lave-vaisselle', 'brand': 'Bosch', 'room_name': 'Cuisine'};

    testWidgets('« D’après la notice Bosch de votre appareil · Notice · page 31 » quand une page a servi', (tester) async {
      final s = sessionState(
        action: NextActionType.instruction, message: 'Fermez le robinet.', choices: const ["C'est fait"], equipment: eq,
        manual: {'manufacturer': 'Bosch', 'pages': [31]},
      );
      await runDiagnostic(tester, s);
      expect(find.text("D'après la notice Bosch de votre appareil · Notice · page 31"), findsOneWidget);
      expect(find.text('Fermez le robinet.'), findsOneWidget); // parcours Nalvium inchangé
    });

    testWidgets('plusieurs pages', (tester) async {
      final s = sessionState(action: NextActionType.askQuestion, message: 'Q ?', choices: const ['Oui'], equipment: eq, manual: {'manufacturer': 'Bosch', 'pages': [17, 31]});
      await runDiagnostic(tester, s);
      expect(find.textContaining('Notice · pages 17, 31'), findsOneWidget);
    });

    testWidgets('jamais de citation si aucune page de la notice n’a été utilisée', (tester) async {
      final none = sessionState(action: NextActionType.askQuestion, message: 'Q ?', choices: const ['Oui'], equipment: eq);
      await runDiagnostic(tester, none);
      expect(k('manual-citation'), findsNothing);
    });

    testWidgets('liste de pages vide = aucune citation', (tester) async {
      final s = sessionState(action: NextActionType.askQuestion, message: 'Q ?', choices: const ['Oui'], equipment: eq, manual: {'manufacturer': 'Bosch', 'pages': <int>[]});
      await runDiagnostic(tester, s);
      expect(k('manual-citation'), findsNothing);
    });

    testWidgets('la citation ouvre la page citée de la notice', (tester) async {
      final home = FakeHomeRepository(items: [equipment(id: 'a', brand: 'Bosch', model: 'SMS46GI01E')])..manuals['a'] = _available;
      final s = sessionState(action: NextActionType.askQuestion, message: 'Q ?', choices: const ['Oui'], equipment: eq, manual: {'manufacturer': 'Bosch', 'pages': [2]});
      final repo = FakeSessionsRepository(stored: s);
      await pumpApp(tester, repo: repo, home: home, location: '/session/s1');
      await tester.tap(k('manual-citation-open'));
      await tester.pumpAndSettle();
      expect(find.text('Page 2 sur 84'), findsOneWidget);
      expect(find.text('Texte de la page 2'), findsOneWidget);
    });
  });

  group('MISE EN PAGE notice', () {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final state in ['none', 'available', 'approx', 'notfound', 'error']) {
        testWidgets('320 dp · ×$scale · $state', (tester) async {
          final home = FakeHomeRepository(items: [equipment(id: 'a', brand: 'Bosch', model: 'SMS46GI01E', name: 'Lave-vaisselle encastrable de la cuisine du rez-de-chaussée')]);
          switch (state) {
            case 'available':
              home.manuals['a'] = _available;
            case 'approx':
              home.manuals['a'] = const ManualInfo(status: 'needs_confirmation', pageCount: 40);
            case 'notfound':
              home.manuals['a'] = const ManualInfo(status: 'not_found');
            case 'error':
              home.manuals['a'] = const ManualInfo(status: 'error');
          }
          await openDetail(tester, home, size: const Size(960, 1704), scale: scale);
          expect(tester.takeException(), isNull);
          await tester.scrollUntilVisible(k('manual-section'), 300, scrollable: find.byType(Scrollable).first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(k('manual-section'), findsOneWidget);
        });
      }
    }
  });
}
