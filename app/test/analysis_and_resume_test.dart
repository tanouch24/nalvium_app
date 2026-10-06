import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/core/network/api_exceptions.dart';
import 'package:nalvium/core/widgets/buttons.dart';
import 'package:nalvium/domain/diagnosis.dart';
import 'package:nalvium/domain/session.dart';
import 'package:nalvium/services/photo_capture_service.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

Future<void> startPhoto(WidgetTester tester, FakeSessionsRepository repo) async {
  await pumpApp(tester, repo: repo, captures: [CapturedPhoto(tempPhotoPath('x'))]);
  await tester.tap(find.byKey(const Key('take-photo')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('use-photo')));
}

void main() {
  testWidgets('ANALYSE : attente honnête (photo, texte Nalvium, phrases d\'attente, aucun faux pourcentage)', (tester) async {
    final repo = FakeSessionsRepository(turns: [sessionState()])..turnGate = Completer<void>();
    await pumpApp(tester, repo: repo, captures: [CapturedPhoto(tempPhotoPath('x'))]);
    await tester.tap(find.byKey(const Key('take-photo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('use-photo')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('J\'analyse le problème…'), findsOneWidget);
    expect(find.byType(Image), findsWidgets); // la photo prise est visible
    expect(find.text('Je regarde ce qui pourrait provoquer ça.'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.textContaining('%'), findsNothing);
    expect(find.textContaining('IA'), findsNothing); // pas de jargon

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('J\'observe les éléments visibles.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Je vérifie ce qui mérite votre attention.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 15));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Cela prend un peu plus de temps que d\'habitude…'), findsOneWidget);

    repo.turnGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Question ?'), findsOneWidget);
  });

  testWidgets('ANALYSE : « Réduire les animations » → aucune animation permanente', (tester) async {
    final repo = FakeSessionsRepository(turns: [sessionState()])..turnGate = Completer<void>();
    await pumpApp(tester, repo: repo, captures: [CapturedPhoto(tempPhotoPath('x'))], reduceMotion: true);
    await tester.tap(find.byKey(const Key('take-photo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('use-photo')));
    await tester.pumpAndSettle(); // ne se bloque pas : rien ne pulse
    expect(find.text('J\'analyse le problème…'), findsOneWidget);
    repo.turnGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('ANALYSE : Annuler revient à l\'accueil', (tester) async {
    final repo = FakeSessionsRepository(turns: [sessionState()])..turnGate = Completer<void>();
    await pumpApp(tester, repo: repo, captures: [CapturedPhoto(tempPhotoPath('x'))]);
    await tester.tap(find.byKey(const Key('take-photo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('use-photo')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('cancel-analysis')));
    await tester.pumpAndSettle();
    expect(find.text('Un problème à la maison ?'), findsOneWidget);
    repo.turnGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('erreur réseau à l\'upload : Réessayer reprend sans recréer la session', (tester) async {
    final repo = FakeSessionsRepository(turns: [sessionState()]);
    // 1er upload échoue
    final failing = _FlakyUploadRepo(repo);
    await pumpApp(tester, repo: failing, captures: [CapturedPhoto(tempPhotoPath('x'))]);
    await tester.tap(find.byKey(const Key('take-photo')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('use-photo')));
    await tester.pumpAndSettle();
    expect(find.text('Impossible de joindre Nalvium'), findsOneWidget);

    await tester.tap(find.byKey(const Key('retry')));
    await tester.pumpAndSettle();
    expect(repo.calls.where((c) => c == 'create').length, 1);
    expect(find.text('Question ?'), findsOneWidget);
  });

  testWidgets('moteur indisponible (503) : état d\'erreur approprié, pas de faux résultat', (tester) async {
    final repo = FakeSessionsRepository(turns: [const ApiHttpException(503, 'analysis_unavailable')]);
    await startPhoto(tester, repo);
    await tester.pumpAndSettle();
    expect(find.text('L\'analyse n\'est pas disponible pour le moment'), findsOneWidget);
    expect(find.byKey(const Key('nalvium-message')), findsNothing);
  });

  testWidgets('retry après 503 : relance l\'analyse SANS renvoyer l\'entrée', (tester) async {
    final repo = FakeSessionsRepository(turns: [const ApiHttpException(503, 'analysis_unavailable'), sessionState(message: 'Enfin !')]);
    await startPhoto(tester, repo);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('retry')));
    await tester.pumpAndSettle();
    expect(repo.inputs[0], isA<PhotoTurn>());
    expect(repo.inputs[1], isNull);
    expect(find.text('Enfin !'), findsOneWidget);
  });

  testWidgets('Annuler pendant l\'attente revient à l\'accueil', (tester) async {
    final repo = FakeSessionsRepository(turns: [const ApiTimeoutException()]);
    await startPhoto(tester, repo);
    await tester.pumpAndSettle();
    expect(find.text('L\'analyse prend trop de temps'), findsOneWidget);
    await tester.tap(find.byKey(const Key('back-home')));
    await tester.pumpAndSettle();
    expect(find.text('Un problème à la maison ?'), findsOneWidget);
  });

  group('Décrire le problème', () {
    testWidgets('Continuer est désactivé tant que le champ est vide', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byKey(const Key('describe-problem')));
      await tester.pumpAndSettle();
      expect(find.text('Que se passe-t-il ?'), findsOneWidget);
      expect(tester.widget<PrimaryButton>(find.byKey(const Key('describe-continue'))).onPressed, isNull);
    });

    testWidgets('texte → session → même moteur guidé', (tester) async {
      final repo = FakeSessionsRepository(turns: [
        sessionState(action: NextActionType.requestPhoto, message: 'Montrez-moi le robinet.'),
      ]);
      await pumpApp(tester, repo: repo);
      await tester.tap(find.byKey(const Key('describe-problem')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('describe-field')), 'Mon robinet goutte');
      await tester.pump();
      await tester.tap(find.byKey(const Key('describe-continue')));
      await tester.pumpAndSettle();
      expect(repo.calls.where((c) => c != 'list' && c != 'get'), ['create', 'turn']); // pas d'upload : texte seul
      expect((repo.inputs.single as DescriptionTurn).text, 'Mon robinet goutte');
      expect(find.text('Montrez-moi le robinet.'), findsOneWidget);
    });

    testWidgets('texte dangereux : SAFETY_STOP affiché', (tester) async {
      final repo = FakeSessionsRepository(turns: [
        sessionState(action: NextActionType.safetyStop, message: 'Arrêtez-vous ici. Gaz : sortez.', status: 'stopped'),
      ]);
      await pumpApp(tester, repo: repo);
      await tester.tap(find.byKey(const Key('describe-problem')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('describe-field')), 'ça sent le gaz');
      await tester.pump();
      await tester.tap(find.byKey(const Key('describe-continue')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('safety-title')), findsOneWidget);
    });
  });

  group('À reprendre / Historique', () {
    testWidgets('aucune session → aucune section « À reprendre »', (tester) async {
      await pumpApp(tester, repo: FakeSessionsRepository());
      expect(find.text('À reprendre'), findsNothing);
      expect(find.byKey(const Key('resume-session')), findsNothing);
    });

    testWidgets('session active réelle → carte « À reprendre » → rouvre la session', (tester) async {
      final repo = FakeSessionsRepository(
        sessions: [summary(state: 'INSTRUCTION')],
        stored: sessionState(action: NextActionType.instruction, message: 'Fermez le robinet.', step: 1),
      );
      await pumpApp(tester, repo: repo);
      expect(find.text('À reprendre'), findsOneWidget);
      expect(find.text('Fuite sous l\'évier'), findsOneWidget);
      expect(find.textContaining('Fermez le robinet'), findsNothing);
      expect(find.text('Continuer'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('resume-session')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('resume-session')));
      await tester.pumpAndSettle();
      expect(find.text('Fermez le robinet.'), findsOneWidget);
      expect(find.text('Essayez ceci'), findsOneWidget);
    });

    testWidgets('sessions terminées ne sont pas « À reprendre » mais sont dans l\'Historique', (tester) async {
      final repo = FakeSessionsRepository(sessions: [summary(id: 'a', status: 'resolved', state: 'RESOLVED', title: 'Robinet réparé')]);
      await pumpApp(tester, repo: repo);
      expect(find.text('À reprendre'), findsNothing);
      await tester.tap(find.byKey(const Key('open-history')));
      await tester.pumpAndSettle();
      expect(find.text('Robinet réparé'), findsOneWidget);
      expect(find.text('Résolu'), findsOneWidget);
      expect(find.text('Aujourd\'hui'), findsNothing);
    });

    testWidgets('historique vide : état vide honnête', (tester) async {
      await pumpApp(tester, repo: FakeSessionsRepository());
      await tester.tap(find.byKey(const Key('open-history')));
      await tester.pumpAndSettle();
      expect(find.text('Aucun historique'), findsOneWidget);
    });

    testWidgets('backend injoignable : l\'accueil reste propre (pas de section, pas de crash)', (tester) async {
      final repo = FakeSessionsRepository()..listError = const ApiNetworkException();
      await pumpApp(tester, repo: repo);
      expect(find.text('À reprendre'), findsNothing);
      expect(find.text('Un problème à la maison ?'), findsOneWidget);
    });
  });
}

/// Premier upload en échec réseau, puis délègue.
class _FlakyUploadRepo extends FakeSessionsRepository {
  _FlakyUploadRepo(this.inner) : super();

  @override
  Future<SessionState> getSession(String sessionId) => inner.getSession(sessionId);

  @override
  Future<List<SessionSummary>> listSessions({bool activeOnly = false}) => inner.listSessions(activeOnly: activeOnly);

  final FakeSessionsRepository inner;
  bool _failed = false;

  @override
  Future<String> createSession({String? equipmentId}) => inner.createSession(equipmentId: equipmentId);

  @override
  Future<String> uploadPhoto(String sessionId, String filePath) async {
    if (!_failed) {
      _failed = true;
      throw const ApiNetworkException();
    }
    return inner.uploadPhoto(sessionId, filePath);
  }

  @override
  Future<SessionState> sendTurn(String sessionId, TurnInput? input) => inner.sendTurn(sessionId, input);
}
