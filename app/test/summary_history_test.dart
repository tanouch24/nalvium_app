import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/core/network/api_exceptions.dart';
import 'package:nalvium/domain/diagnosis.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

void main() {
  group('HISTORIQUE', () {
    testWidgets('vraies sessions : titre, état avec libellé, date ; pas de dump de conversation', (tester) async {
      final now = DateTime.now();
      final repo = FakeSessionsRepository(sessions: [
        summary(id: 'a', title: 'Robinet qui goutte', status: 'resolved', state: 'RESOLVED', updatedAt: now),
        summary(id: 'b', title: 'Câble qui chauffe', status: 'stopped', state: 'SAFETY_STOP', category: 'electrical', updatedAt: now.subtract(const Duration(days: 1))),
        summary(id: 'c', title: 'Machine en panne', status: 'referred', state: 'RECOMMEND_PROFESSIONAL', category: 'appliance', updatedAt: DateTime(2025, 3, 12)),
        summary(id: 'd', title: 'Lave-vaisselle', status: 'active', state: 'INSTRUCTION', category: 'appliance', updatedAt: now),
      ]);
      await pumpApp(tester, repo: repo);
      await tester.tap(find.byKey(const Key('open-history')));
      await tester.pumpAndSettle();
      for (final t in ['Robinet qui goutte', 'Câble qui chauffe', 'Machine en panne', 'Lave-vaisselle']) {
        expect(find.text(t), findsOneWidget);
      }
      expect(find.text('Résolu'), findsOneWidget);
      expect(find.text('Arrêt de sécurité'), findsOneWidget);
      expect(find.text('Professionnel recommandé'), findsOneWidget);
      expect(find.text('À reprendre'), findsOneWidget); // statut d'une session active
      expect(find.byKey(const Key('history-intro')), findsOneWidget);
      expect(find.text('Les problèmes que Nalvium vous a aidé à traiter.'), findsOneWidget);
      expect(find.textContaining('Électroménager'), findsNothing); // pas de métadonnées techniques
      expect(find.textContaining('Hier'), findsOneWidget);
      expect(find.textContaining('mars 2025'), findsOneWidget);
      expect(find.textContaining('Utilisateur:'), findsNothing);
    });

    testWidgets('session active → reprise ; terminée → récapitulatif', (tester) async {
      final repo = FakeSessionsRepository(
        sessions: [
          summary(id: 'a', title: 'Réglé', status: 'resolved', state: 'RESOLVED'),
          summary(id: 'b', title: 'En cours', status: 'active', state: 'INSTRUCTION'),
        ],
        stored: sessionState(action: NextActionType.instruction, message: 'Fermez le robinet.', id: 'b'),
      );
      await pumpApp(tester, repo: repo);
      await tester.tap(find.byKey(const Key('open-history')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('history-b')));
      await tester.pumpAndSettle();
      expect(find.text('Fermez le robinet.'), findsOneWidget); // écran guidé

      await tester.tap(find.byKey(const Key('close-session')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open-history')));
      await tester.pumpAndSettle();

      repo.stored = sessionState(action: NextActionType.resolved, message: 'Le filtre était bouché.', status: 'resolved', id: 'a');
      await tester.tap(find.byKey(const Key('history-a')));
      await tester.pumpAndSettle();
      expect(find.text('Récapitulatif'), findsOneWidget);
      expect(find.text('Le filtre était bouché.'), findsOneWidget);
      expect(find.text('Résultat'), findsOneWidget);
    });

    testWidgets('erreur de chargement : message + Réessayer', (tester) async {
      final repo = FakeSessionsRepository();
      await pumpApp(tester, repo: repo);
      repo.listError = const ApiNetworkException();
      await tester.tap(find.byKey(const Key('open-history')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('retry')), findsOneWidget);
    });
  });

  group('RÉCAPITULATIF', () {
    testWidgets('session résolue : conclusion, observations réelles, étapes avec statut', (tester) async {
      final repo = FakeSessionsRepository(
        stored: sessionState(
          action: NextActionType.resolved,
          message: 'Le filtre était encrassé : le problème est réglé.',
          status: 'resolved',
          title: 'Lave-vaisselle n\'évacue pas',
          category: 'appliance',
          observations: ['Eau stagnante au fond de la cuve'],
          actions: [
            {'step_number': 1, 'instruction': 'Retirez le filtre et rincez-le.', 'status': 'done'},
            {'step_number': 2, 'instruction': 'Vérifiez la pompe.', 'status': 'failed'},
          ],
        ),
      );
      await pumpApp(tester, repo: repo, location: '/session/s1/summary');
      expect(find.byKey(const Key('summary-title')), findsOneWidget);
      expect(find.text('Lave-vaisselle n\'évacue pas'), findsOneWidget);
      expect(find.textContaining('Résolu'), findsOneWidget);
      expect(find.textContaining('Électroménager'), findsOneWidget);
      // trois zones : Problème (titre + observations) / Ce qu'on a fait / Résultat
      expect(find.text('Ce qu\'on a fait'), findsOneWidget);
      expect(find.text('Résultat'), findsOneWidget);
      expect(find.text('Eau stagnante au fond de la cuve'), findsOneWidget);
      expect(find.text('Retirez le filtre et rincez-le.'), findsOneWidget);
      expect(find.text('Fait'), findsOneWidget);
      expect(find.text('Pas réussi'), findsOneWidget);
      expect(find.byKey(const Key('summary-conclusion')), findsOneWidget);
    });

    testWidgets('session arrêtée : aucune étape DIY présentée', (tester) async {
      final repo = FakeSessionsRepository(
        stored: sessionState(
          action: NextActionType.safetyStop,
          message: 'Arrêtez-vous ici. Le câble est sous tension.',
          status: 'stopped',
          actions: [
            {'step_number': 1, 'instruction': 'Faites ceci', 'status': 'done'},
          ],
        ),
      );
      await pumpApp(tester, repo: repo, location: '/session/s1/summary');
      expect(find.textContaining('Arrêt de sécurité'), findsOneWidget);
      expect(find.text('Le câble est sous tension.'), findsOneWidget);
      expect(find.text('Ce qu\'on a fait'), findsNothing);
    });

    testWidgets('erreur : message honnête et Réessayer', (tester) async {
      final repo = FakeSessionsRepository()..getError = const ApiNetworkException();
      await pumpApp(tester, repo: repo, location: '/session/s1/summary');
      expect(find.byKey(const Key('retry')), findsOneWidget);
    });
  });
}
