import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/core/network/api_exceptions.dart';
import 'package:nalvium/core/widgets/buttons.dart';
import 'package:nalvium/core/widgets/choice_tile.dart';
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
        sessionState(action: NextActionType.instruction, message: 'Fermez le robinet d\'arrêt sous le lavabo.', items: ['Un torchon'], messages: 4),
        sessionState(action: NextActionType.verification, message: 'L\'eau s\'évacue-t-elle maintenant ?', choices: ['Oui', 'Un peu', 'Non', 'Je ne sais pas'], messages: 6),
        sessionState(action: NextActionType.resolved, message: 'Le problème semble résolu.', status: 'resolved', messages: 8),
      ],
    );
    expect(find.text('J\'ai besoin de vérifier un point'), findsOneWidget);
    expect(find.textContaining('quand vous ouvrez le robinet'), findsOneWidget);

    await tester.tap(find.byKey(const Key('choice-Oui')));
    await tester.pumpAndSettle();
    expect((repo.inputs[0] as AnswerTurn).text, 'Oui');
    expect(find.text('Essayez ceci'), findsOneWidget);
    expect(find.text('Action'), findsOneWidget);
    expect(find.text('Vous aurez besoin de'), findsOneWidget);
    expect(find.text('Un torchon'), findsOneWidget);
    expect(find.textContaining('Étape'), findsNothing); // jamais « Étape 2/7 »

    await tester.tap(find.byKey(const Key('action-done')));
    await tester.pumpAndSettle();
    expect((repo.inputs[1] as ActionResultTurn).choice, ActionChoice.done);
    expect(find.text('Vérifions'), findsOneWidget);
    expect(find.text('Contrôle'), findsOneWidget);

    await tester.tap(find.byKey(const Key('choice-Oui')));
    await tester.pumpAndSettle();
    expect((repo.inputs[2] as AnswerTurn).text, 'Oui');
    expect(find.text('C\'est réglé'), findsOneWidget);
  });

  testWidgets('ASK_QUESTION : titre dédié, grandes réponses, réponse libre', (tester) async {
    final repo = await openSession(
      tester,
      sessionState(message: 'Où voyez-vous l\'eau ?', choices: ['Sous l\'évier', 'Au mur']),
      turns: [sessionState(action: NextActionType.requestPhoto, message: 'Montrez-moi le mur.')],
    );
    expect(find.text('Observation'), findsOneWidget);
    expect(find.byType(ChoiceTile), findsNWidgets(2));
    expect(find.byKey(const Key('answer-field')), findsNothing); // pas de clavier si les boutons suffisent
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
    expect(tester.widget<PrimaryButton>(find.byKey(const Key('send-answer'))).onPressed, isNull); // désactivé tant que vide
  });

  testWidgets('REQUEST_PHOTO : « Montrez-moi ce point », nouvelle photo dans la MÊME session', (tester) async {
    final repo = await openSession(
      tester,
      sessionState(action: NextActionType.requestPhoto, message: 'Prenez une photo du raccord sous l\'évier, vue de face.', mediaId: 'm0'),
      captures: [CapturedPhoto(tempPhotoPath('req'))],
      turns: [sessionState(action: NextActionType.instruction, message: 'Fermez le robinet.')],
    );
    expect(find.text('Montrez-moi ce point'), findsOneWidget);
    expect(find.textContaining('raccord sous l\'évier'), findsOneWidget);
    await tester.tap(find.byKey(const Key('take-requested-photo')));
    await tester.pumpAndSettle();
    expect(repo.calls, containsAllInOrder(['upload', 'turn']));
    expect(repo.calls.where((c) => c == 'create'), isEmpty); // pas de nouvelle session
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

  testWidgets('INSTRUCTION : une seule action, trois réponses, réévaluation', (tester) async {
    final repo = await openSession(
      tester,
      sessionState(action: NextActionType.instruction, message: 'Retirez le filtre au fond du lave-vaisselle.'),
      turns: [
        sessionState(action: NextActionType.instruction, message: 'Utilisez une pince.', messages: 4),
        sessionState(action: NextActionType.requestPhoto, message: 'Montrez-moi ce que vous voyez.', messages: 6),
      ],
    );
    expect(find.text('Essayez ceci'), findsOneWidget);
    expect(find.text('C\'est fait'), findsOneWidget);
    expect(find.text('Je n\'y arrive pas'), findsOneWidget);
    expect(find.text('Ce n\'est pas ce que je vois'), findsOneWidget);
    expect(find.text('Vous aurez besoin de'), findsNothing); // seulement si le backend en fournit
    await tester.tap(find.byKey(const Key('action-cannot')));
    await tester.pumpAndSettle();
    expect((repo.inputs[0] as ActionResultTurn).choice, ActionChoice.cannot);
    expect(find.text('Utilisez une pince.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('action-mismatch')));
    await tester.pumpAndSettle();
    expect((repo.inputs[1] as ActionResultTurn).choice, ActionChoice.mismatch);
    expect(find.text('Montrez-moi ce que vous voyez.'), findsOneWidget);
  });

  testWidgets('VERIFICATION : Oui / Un peu / Non / Je ne sais pas par défaut, photo possible', (tester) async {
    await openSession(tester, sessionState(action: NextActionType.verification, message: 'L\'eau s\'évacue-t-elle maintenant ?'));
    final labels = tester.widgetList<ChoiceTile>(find.byType(ChoiceTile)).map((c) => c.label).toList();
    expect(labels, ['Oui', 'Un peu', 'Non', 'Je ne sais pas']);
    expect(find.byKey(const Key('verify-with-photo')), findsOneWidget);
  });

  testWidgets('VERIFICATION : « Un peu » est envoyé au backend (qui l\'évalue : improved…)', (tester) async {
    final repo = await openSession(
      tester,
      sessionState(action: NextActionType.verification, message: 'Ça fuit encore ?'),
      turns: [sessionState(action: NextActionType.instruction, message: 'Resserrez le raccord.')],
    );
    await tester.tap(find.byKey(const Key('choice-Un peu')));
    await tester.pumpAndSettle();
    expect((repo.inputs.single as AnswerTurn).text, 'Un peu');
  });

  testWidgets('RESOLVED : moment de fin sobre, récapitulatif accessible', (tester) async {
    await openSession(
      tester,
      sessionState(action: NextActionType.resolved, message: 'Le filtre était bouché.', status: 'resolved'),
    );
    expect(find.text('C\'est réglé'), findsOneWidget);
    expect(find.text('Le filtre était bouché.'), findsOneWidget);
    expect(find.byKey(const Key('resolved-finish')), findsOneWidget);
    await tester.tap(find.byKey(const Key('resolved-summary')));
    await tester.pumpAndSettle();
    expect(find.text('Récapitulatif'), findsOneWidget);
  });

  testWidgets('RESOLVED → Terminer : retour accueil, et la session n\'est plus « À reprendre »', (tester) async {
    final repo = FakeSessionsRepository(
      stored: sessionState(action: NextActionType.resolved, message: 'Réglé.', status: 'resolved'),
      sessions: [summary(status: 'resolved', state: 'RESOLVED')],
    );
    await pumpApp(tester, repo: repo, location: '/session/s1');
    await tester.tap(find.byKey(const Key('resolved-finish')));
    await tester.pumpAndSettle();
    expect(find.text('Un problème à la maison ?'), findsOneWidget);
    expect(find.text('À reprendre'), findsNothing);
  });

  testWidgets('SAFETY_STOP : impossible à confondre, aucune action DIY', (tester) async {
    await openSession(
      tester,
      sessionState(action: NextActionType.safetyStop, message: 'Arrêtez-vous ici. Ça sent le gaz : sortez et appelez le 112.', status: 'stopped'),
    );
    expect(find.byKey(const Key('safety-title')), findsOneWidget);
    expect(find.text('Arrêtez-vous ici'), findsOneWidget);
    expect(find.text('Ça sent le gaz : sortez et appelez le 112.'), findsOneWidget); // préfixe non répété
    // Phase 5 : « Demander de l'aide » est l'action principale ; aucune action de réparation.
    expect(find.byKey(const Key('safety-find-pro')), findsOneWidget);
    expect(find.byType(PrimaryButton), findsOneWidget);
    expect(find.byType(DangerButton), findsNothing);
    expect(find.byType(ChoiceTile), findsNothing);
    for (final k in ['action-done', 'action-cannot', 'take-requested-photo', 'send-answer', 'verify-with-photo']) {
      expect(find.byKey(Key(k)), findsNothing);
    }
    expect(find.byKey(const Key('category-label')), findsNothing); // pas de diagnostic « normal » autour
  });

  testWidgets('SAFETY_STOP : « Compris » ramène à l\'accueil', (tester) async {
    await openSession(tester, sessionState(action: NextActionType.safetyStop, message: 'Arrêtez-vous ici. Sortez.', status: 'stopped'));
    await tester.tap(find.byKey(const Key('safety-understood')));
    await tester.pumpAndSettle();
    expect(find.text('Un problème à la maison ?'), findsOneWidget);
  });

  testWidgets('RECOMMEND_PROFESSIONAL : calme, « Demander de l\'aide » → demande d\'intervention', (tester) async {
    await openSession(
      tester,
      sessionState(action: NextActionType.recommendProfessional, message: 'Le moteur doit être démonté.', status: 'referred'),
    );
    expect(find.text('Cette intervention demande un professionnel'), findsOneWidget);
    expect(find.text('Le moteur doit être démonté.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('see-repair-options')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('help-intro')), findsOneWidget); // formulaire de demande avec le contexte du diagnostic
  });

  testWidgets('reprise : une session pendante relance l\'analyse sans dupliquer l\'entrée', (tester) async {
    final repo = await openSession(
      tester,
      sessionState(pending: true, message: 'ancien'),
      turns: [sessionState(message: 'Voici ma question.')],
    );
    expect(repo.inputs, [null]);
    expect(find.text('Voici ma question.'), findsOneWidget);
  });

  testWidgets('reprise : l\'écran est reconstruit depuis le backend', (tester) async {
    final repo = await openSession(tester, sessionState(action: NextActionType.instruction, message: 'Fermez le robinet.'));
    expect(repo.calls.first, 'get');
    expect(find.text('Essayez ceci'), findsOneWidget);
    expect(find.text('Fermez le robinet.'), findsOneWidget);
  });

  testWidgets('catégorie réelle dans la barre du haut', (tester) async {
    await openSession(tester, sessionState(category: 'electrical'));
    expect(find.byKey(const Key('category-label')), findsOneWidget);
    expect(find.text('Électricité'), findsOneWidget);
  });

  group('erreurs réseau', () {
    testWidgets('erreur réseau pendant un tour → message + Réessayer sans doublon', (tester) async {
      final repo = await openSession(
        tester,
        sessionState(message: 'Question ?', choices: ['Oui', 'Non'], messages: 2),
        turns: [const ApiNetworkException(), sessionState(action: NextActionType.instruction, message: 'Étape.', messages: 4)],
      );
      await tester.tap(find.byKey(const Key('choice-Oui')));
      await tester.pumpAndSettle();
      expect(find.text('Impossible de joindre Nalvium'), findsOneWidget);
      await tester.tap(find.byKey(const Key('retry')));
      await tester.pumpAndSettle();
      expect(find.text('Étape.'), findsOneWidget);
      expect(repo.inputs.map((i) => (i as AnswerTurn).text), ['Oui', 'Oui']);
    });

    testWidgets('timeout : message dédié, jamais de spinner infini', (tester) async {
      await openSession(tester, sessionState(message: 'Q', choices: ['Oui']), turns: [const ApiTimeoutException()]);
      await tester.tap(find.byKey(const Key('choice-Oui')));
      await tester.pumpAndSettle();
      expect(find.text('L\'analyse prend trop de temps'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('analyse indisponible (503) : état honnête', (tester) async {
      await openSession(tester, sessionState(message: 'Q', choices: ['Oui']), turns: [const ApiHttpException(503, 'analysis_unavailable')]);
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
