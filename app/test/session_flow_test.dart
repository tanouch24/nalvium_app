import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/core/network/api_exceptions.dart';
import 'package:nalvium/domain/diagnosis.dart';
import 'package:nalvium/domain/session.dart';
import 'package:nalvium/services/photo_capture_service.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

Future<FakeSessionsRepository> openSession(WidgetTester tester, SessionState state, {List<Object?> captures = const [null], List<Object> turns = const []}) async {
  final repo = FakeSessionsRepository(stored: state, turns: turns);
  await pumpApp(tester, repo: repo, captures: captures, location: '/session/s1');
  return repo;
}

void main() {
  testWidgets('parcours complet : question → instruction → vérification → résolu', (tester) async {
    final repo = await openSession(
      tester,
      sessionState(message: 'L\'eau apparaît-elle quand vous ouvrez le robinet ?', choices: ['Oui', 'Non', 'Je ne sais pas']),
      turns: [
        sessionState(action: NextActionType.instruction, message: 'Fermez le robinet d\'arrêt sous le lavabo.', step: 1, items: ['Un torchon']),
        sessionState(action: NextActionType.verification, message: 'L\'eau coule-t-elle encore ?', choices: ['Non', 'Oui', 'Je ne sais pas']),
        sessionState(action: NextActionType.resolved, message: 'Le problème semble résolu.', status: 'resolved'),
      ],
    );
    expect(find.textContaining('quand vous ouvrez le robinet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('choice-Oui')));
    await tester.pumpAndSettle();
    expect((repo.inputs[0] as AnswerTurn).text, 'Oui');
    expect(find.byKey(const Key('step-label')), findsOneWidget);
    expect(find.text('Étape 1'), findsOneWidget);
    expect(find.textContaining('Un torchon'), findsOneWidget);

    await tester.tap(find.byKey(const Key('action-done')));
    await tester.pumpAndSettle();
    expect((repo.inputs[1] as ActionResultTurn).choice, ActionChoice.done);
    expect(find.text('L\'eau coule-t-elle encore ?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('choice-Non')));
    await tester.pumpAndSettle();
    expect((repo.inputs[2] as AnswerTurn).text, 'Non');
    expect(find.byKey(const Key('resolved-title')), findsOneWidget);
    expect(find.text('Problème résolu'), findsOneWidget);
  });

  testWidgets('ASK_QUESTION : réponse libre', (tester) async {
    final repo = await openSession(
      tester,
      sessionState(message: 'Où voyez-vous l\'eau ?', choices: ['Sous l\'évier', 'Au mur']),
      turns: [sessionState(action: NextActionType.requestPhoto, message: 'Montrez-moi le mur.')],
    );
    await tester.tap(find.byKey(const Key('answer-otherwise')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('answer-field')), 'Derrière la machine');
    await tester.pump();
    await tester.tap(find.byKey(const Key('send-answer')));
    await tester.pumpAndSettle();
    expect((repo.inputs.single as AnswerTurn).text, 'Derrière la machine');
  });

  testWidgets('ASK_QUESTION sans choix : champ texte direct', (tester) async {
    await openSession(tester, sessionState(message: 'Que voyez-vous ?'));
    expect(find.byKey(const Key('answer-field')), findsOneWidget);
  });

  testWidgets('REQUEST_PHOTO : nouvelle photo uploadée puis analysée avec le contexte', (tester) async {
    final repo = await openSession(
      tester,
      sessionState(action: NextActionType.requestPhoto, message: 'Montrez-moi la connexion sous le lavabo.'),
      captures: [CapturedPhoto(tempPhotoPath('req'))],
      turns: [sessionState(action: NextActionType.instruction, message: 'Fermez le robinet.', step: 1)],
    );
    expect(find.text('Montrez-moi la connexion sous le lavabo.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('take-requested-photo')));
    await tester.pumpAndSettle();
    expect(repo.calls, containsAllInOrder(['upload', 'turn']));
    expect(repo.inputs.single, isA<PhotoTurn>());
    expect(find.text('Fermez le robinet.'), findsOneWidget);
  });

  testWidgets('REQUEST_PHOTO : annuler la caméra ne lance aucune analyse', (tester) async {
    final repo = await openSession(tester, sessionState(action: NextActionType.requestPhoto, message: 'Une photo ?'));
    await tester.tap(find.byKey(const Key('take-requested-photo')));
    await tester.pumpAndSettle();
    expect(repo.calls.where((c) => c == 'turn'), isEmpty);
  });

  testWidgets('REQUEST_PHOTO : « Je ne peux pas » répond par texte', (tester) async {
    final repo = await openSession(
      tester,
      sessionState(action: NextActionType.requestPhoto, message: 'Une photo ?'),
      turns: [sessionState(message: 'D\'accord, décrivez-moi.')],
    );
    await tester.tap(find.byKey(const Key('cannot-take-photo')));
    await tester.pumpAndSettle();
    expect((repo.inputs.single as AnswerTurn).text, 'Je ne peux pas prendre cette photo.');
  });

  testWidgets('INSTRUCTION : « Je n\'y arrive pas » et « Ce n\'est pas ce que je vois » réévaluent', (tester) async {
    final repo = await openSession(
      tester,
      sessionState(action: NextActionType.instruction, message: 'Fermez le robinet.', step: 1),
      turns: [
        sessionState(action: NextActionType.instruction, message: 'Utilisez une pince.', step: 2),
        sessionState(action: NextActionType.requestPhoto, message: 'Montrez-moi ce que vous voyez.'),
      ],
    );
    expect(find.text('C\'est fait'), findsOneWidget);
    await tester.tap(find.byKey(const Key('action-cannot')));
    await tester.pumpAndSettle();
    expect((repo.inputs[0] as ActionResultTurn).choice, ActionChoice.cannot);
    expect(find.text('Étape 2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('action-mismatch')));
    await tester.pumpAndSettle();
    expect((repo.inputs[1] as ActionResultTurn).choice, ActionChoice.mismatch);
    expect(find.text('Montrez-moi ce que vous voyez.'), findsOneWidget);
  });

  testWidgets('VERIFICATION : choix par défaut si l\'IA n\'en fournit pas, et nouvelle photo possible', (tester) async {
    await openSession(tester, sessionState(action: NextActionType.verification, message: 'Ça fuit encore ?'));
    expect(find.byKey(const Key('choice-Non')), findsOneWidget);
    expect(find.byKey(const Key('choice-Oui')), findsOneWidget);
    expect(find.byKey(const Key('choice-Je ne sais pas')), findsOneWidget);
    expect(find.byKey(const Key('verify-with-photo')), findsOneWidget);
  });

  testWidgets('SAFETY_STOP : écran distinct, aucune action DIY', (tester) async {
    await openSession(
      tester,
      sessionState(action: NextActionType.safetyStop, message: 'Arrêtez-vous ici. Ça sent le gaz : sortez et appelez le 112.', status: 'stopped'),
    );
    expect(find.byKey(const Key('safety-title')), findsOneWidget);
    expect(find.text('Arrêtez-vous ici'), findsOneWidget);
    expect(find.text('Ça sent le gaz : sortez et appelez le 112.'), findsOneWidget); // préfixe non répété
    expect(find.byKey(const Key('safety-understood')), findsOneWidget);
    for (final k in ['action-done', 'action-cannot', 'take-requested-photo', 'send-answer', 'verify-with-photo']) {
      expect(find.byKey(Key(k)), findsNothing);
    }
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('RECOMMEND_PROFESSIONAL : orientation vers Dépannage', (tester) async {
    await openSession(
      tester,
      sessionState(action: NextActionType.recommendProfessional, message: 'Cette intervention nécessite un professionnel.', status: 'referred'),
    );
    expect(find.text('Cette intervention nécessite un professionnel.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('see-repair-options')));
    await tester.pumpAndSettle();
    expect(find.text('Aucune demande en cours'), findsOneWidget); // onglet Dépannage
  });

  testWidgets('reprise : une session pendante relance l\'analyse sans dupliquer l\'entrée', (tester) async {
    final repo = await openSession(
      tester,
      sessionState(pending: true, message: 'ancien'),
      turns: [sessionState(message: 'Voici ma question.')],
    );
    expect(repo.inputs, [null]); // sendTurn(null) : relance seulement
    expect(find.text('Voici ma question.'), findsOneWidget);
  });

  testWidgets('reprise : l\'écran est reconstruit depuis le backend', (tester) async {
    final repo = await openSession(tester, sessionState(action: NextActionType.instruction, message: 'Fermez le robinet.', step: 3));
    expect(repo.calls, ['get', 'list'].sublist(0, 1));
    expect(find.text('Étape 3'), findsOneWidget);
  });

  group('erreurs réseau', () {
    testWidgets('erreur réseau pendant un tour → message + Réessayer sans doublon', (tester) async {
      final repo = await openSession(
        tester,
        sessionState(message: 'Question ?', choices: ['Oui', 'Non'], messages: 2),
        turns: [const ApiNetworkException(), sessionState(action: NextActionType.instruction, message: 'Étape.', step: 1)],
      );
      await tester.tap(find.byKey(const Key('choice-Oui')));
      await tester.pumpAndSettle();
      expect(find.text('Impossible de joindre Nalvium'), findsOneWidget);

      await tester.tap(find.byKey(const Key('retry')));
      await tester.pumpAndSettle();
      expect(find.text('Étape.'), findsOneWidget);
      // 1ère tentative (échec réseau) + retry : l'état serveur n'avait pas changé => on renvoie l'entrée
      expect(repo.inputs.map((i) => (i as AnswerTurn).text), ['Oui', 'Oui']);
    });

    testWidgets('timeout : message dédié, jamais de spinner infini', (tester) async {
      await openSession(
        tester,
        sessionState(message: 'Q', choices: ['Oui']),
        turns: [const ApiTimeoutException()],
      );
      await tester.tap(find.byKey(const Key('choice-Oui')));
      await tester.pumpAndSettle();
      expect(find.text('L\'analyse prend trop de temps'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('analyse indisponible (503) : état honnête', (tester) async {
      await openSession(
        tester,
        sessionState(message: 'Q', choices: ['Oui']),
        turns: [const ApiHttpException(503, 'analysis_unavailable')],
      );
      await tester.tap(find.byKey(const Key('choice-Oui')));
      await tester.pumpAndSettle();
      expect(find.text('L\'analyse n\'est pas disponible pour le moment'), findsOneWidget);
    });

    testWidgets('chargement de session impossible : erreur + retour accueil', (tester) async {
      final repo = FakeSessionsRepository()..getError = const ApiNetworkException();
      await pumpApp(tester, repo: repo, location: '/session/s1');
      expect(find.text('Impossible de joindre Nalvium'), findsOneWidget);
      await tester.tap(find.byKey(const Key('back-home')));
      await tester.pumpAndSettle();
      expect(find.text('Un problème à la maison ?'), findsOneWidget);
    });
  });
}
