import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/domain/diagnosis.dart';
import 'package:nalvium/domain/session.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

Finder k(String key) => find.byKey(Key(key));

const _longQuestion =
    'Quand vous faites couler l’eau pendant plusieurs minutes, la fuite apparaît-elle uniquement sous le siphon, ou aussi au niveau du raccord mural, ou même quand l’évier n’est pas du tout utilisé ?';
const _longChoice = 'Seulement quand l’eau coule depuis plusieurs minutes, surtout au niveau du raccord mural';

Future<FakeSessionsRepository> open(
  WidgetTester tester, {
  Size size = const Size(720, 1600),
  double dpr = 2,
  double scale = 1.0,
  String message = 'La fuite apparaît-elle uniquement quand vous faites couler l’eau ?',
  List<String> choices = const ['Seulement quand l’eau coule', 'Même à l’arrêt', 'Je ne sais pas'],
  List<Object> turns = const [],
}) async {
  final repo = FakeSessionsRepository(stored: sessionState(message: message, choices: choices), turns: turns);
  await pumpApp(tester, repo: repo, location: '/session/s1', size: size, dpr: dpr, textScale: scale);
  return repo;
}

void main() {
  for (final cfg in [('Samsung 360×800', const Size(720, 1600), 2.0), ('petit écran 320×568', const Size(960, 1704), 3.0)]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('QUESTION ${cfg.$1} · ×$scale · textes longs : aucun overflow, tout est atteignable (≥ 48 dp)', (tester) async {
        await open(tester, size: cfg.$2, dpr: cfg.$3, scale: scale, message: _longQuestion, choices: const [_longChoice, 'Même à l’arrêt', 'Je ne sais pas']);
        expect(tester.takeException(), isNull);
        expect(find.text(_longQuestion), findsOneWidget);
        for (final key in ['choice-$_longChoice', 'choice-Même à l’arrêt', 'choice-Je ne sais pas', 'answer-otherwise', 'ask-for-help', 'close-session']) {
          await tester.scrollUntilVisible(k(key), 120, scrollable: find.byType(Scrollable).first);
          await tester.ensureVisible(k(key));
          await tester.pump();
          expect(tester.getSize(k(key)).height, greaterThanOrEqualTo(48), reason: key);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('QUESTION Samsung ×1 : la question et au moins deux réponses sont visibles sans défiler', (tester) async {
    await open(tester);
    final screen = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(tester.getRect(k('nalvium-message')).bottom, lessThan(screen));
    expect(tester.getRect(k('choice-Même à l’arrêt')).bottom, lessThan(screen));
  });

  testWidgets('QUESTION : la question est le titre le plus grand, l’introduction reste secondaire', (tester) async {
    await open(tester);
    final q = tester.getSize(k('nalvium-message')).height;
    final intro = tester.getSize(k('guidance-title')).height;
    expect(q, greaterThan(intro));
    expect(tester.widget<Text>(k('nalvium-message')).style!.fontSize!, greaterThan(tester.widget<Text>(k('guidance-title')).style!.fontSize!));
  });

  testWidgets('QUESTION : actions inchangées (Observation, Répondre autrement, Demander de l’aide)', (tester) async {
    await open(tester);
    expect(find.text('Observation'), findsOneWidget);
    expect(find.text('J\'ai besoin de vérifier un point'), findsOneWidget);
    expect(k('answer-otherwise'), findsOneWidget);
    expect(k('ask-for-help'), findsOneWidget);
    await tester.tap(k('answer-otherwise'));
    await tester.pump();
    expect(k('answer-field'), findsOneWidget);
    expect(k('send-answer'), findsOneWidget);
  });

  testWidgets('QUESTION : choisir une réponse envoie exactement ce texte (comportement inchangé)', (tester) async {
    final repo = await open(tester, turns: [sessionState(action: NextActionType.instruction, message: 'Fermez le robinet.', messages: 4)]);
    await tester.tap(k('choice-Même à l’arrêt'));
    await tester.pumpAndSettle();
    expect((repo.inputs.single as AnswerTurn).text, 'Même à l’arrêt');
    expect(find.text('Essayez ceci'), findsOneWidget);
  });
}
