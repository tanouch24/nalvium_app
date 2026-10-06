import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/domain/diagnosis.dart';
import 'package:nalvium/domain/session.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

Finder k(String key) => find.byKey(Key(key));

const _longText =
    'Placez une bassine ou un seau juste sous le siphon, puis séchez complètement le siphon et chacun des raccords avec un chiffon sec, afin de repérer précisément d’où l’humidité réapparaît en premier.';

final _configs = [
  ('Samsung 360×800', const Size(720, 1600), 2.0),
  ('petit écran 320×568', const Size(960, 1704), 3.0),
];

Future<FakeSessionsRepository> open(
  WidgetTester tester,
  SessionState state, {
  Size size = const Size(720, 1600),
  double dpr = 2,
  double scale = 1.0,
  List<Object> turns = const [],
}) async {
  final repo = FakeSessionsRepository(stored: state, turns: turns);
  await pumpApp(tester, repo: repo, location: '/session/s1', size: size, dpr: dpr, textScale: scale);
  return repo;
}

Future<void> reach(WidgetTester tester, String key, {int minDp = 48}) async {
  await tester.scrollUntilVisible(k(key), 120, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(k(key));
  await tester.pump();
  expect(tester.getSize(k(key)).height, greaterThanOrEqualTo(minDp), reason: key);
}

void main() {
  for (final cfg in _configs) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('REQUEST_PHOTO ${cfg.$1} · ×$scale : photo existante + zone à prendre + CTA, sans overflow', (tester) async {
        await open(
          tester,
          sessionState(action: NextActionType.requestPhoto, message: _longText, mediaId: 'm0'),
          size: cfg.$2,
          dpr: cfg.$3,
          scale: scale,
        );
        expect(tester.takeException(), isNull);
        expect(find.text(_longText), findsOneWidget);
        for (final key in ['photo-target', 'take-requested-photo', 'cannot-take-photo', 'ask-for-help', 'close-session']) {
          await reach(tester, key);
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('INSTRUCTION ${cfg.$1} · ×$scale : instruction longue, objets, CTA accessibles', (tester) async {
        await open(
          tester,
          sessionState(action: NextActionType.instruction, message: _longText, items: ['Bassine ou seau', 'Chiffon sec', 'Lampe de poche'], step: 2),
          size: cfg.$2,
          dpr: cfg.$3,
          scale: scale,
        );
        expect(tester.takeException(), isNull);
        expect(find.text(_longText), findsOneWidget);
        for (final key in ['action-done', 'action-cannot', 'action-mismatch', 'ask-for-help']) {
          await reach(tester, key);
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('VERIFICATION ${cfg.$1} · ×$scale : question longue, réponses accessibles', (tester) async {
        await open(
          tester,
          sessionState(action: NextActionType.verification, message: _longText, choices: ['Oui', 'Un peu', 'Non', 'Je ne sais pas']),
          size: cfg.$2,
          dpr: cfg.$3,
          scale: scale,
        );
        expect(tester.takeException(), isNull);
        for (final key in ['choice-Oui', 'choice-Un peu', 'choice-Non', 'choice-Je ne sais pas', 'verify-with-photo', 'ask-for-help']) {
          await reach(tester, key);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('VERIFICATION : réponses de la même famille que la question (rayon 16 / pas de pastille)', (tester) async {
    await open(tester, sessionState(action: NextActionType.verification, message: 'Est-ce sec ?', choices: ['Oui', 'Un peu', 'Non', 'Je ne sais pas']));
    expect(find.byType(DecoratedBox), findsWidgets);
    final box = tester.widget<AnimatedContainer>(find.descendant(of: k('choice-Oui'), matching: find.byType(AnimatedContainer)).first);
    final radius = ((box.decoration! as BoxDecoration).borderRadius! as BorderRadius).topLeft.x;
    expect(radius, 16);
  });

  testWidgets('VERIFICATION : choisir une réponse envoie exactement ce texte', (tester) async {
    final repo = await open(
      tester,
      sessionState(action: NextActionType.verification, message: 'Est-ce sec ?', choices: ['Oui', 'Un peu', 'Non', 'Je ne sais pas']),
      turns: [sessionState(action: NextActionType.resolved, message: 'Résolu.', status: 'resolved', messages: 6)],
    );
    await tester.tap(k('choice-Un peu'));
    await tester.pumpAndSettle();
    expect((repo.inputs.single as AnswerTurn).text, 'Un peu');
  });

  testWidgets('INSTRUCTION : « C’est fait » envoie toujours le résultat « done »', (tester) async {
    final repo = await open(
      tester,
      sessionState(action: NextActionType.instruction, message: 'Fermez le robinet.', items: ['Un torchon']),
      turns: [sessionState(action: NextActionType.verification, message: 'Est-ce sec ?', choices: ['Oui', 'Non'], messages: 6)],
    );
    await tester.tap(k('action-done'));
    await tester.pumpAndSettle();
    expect((repo.inputs.single as ActionResultTurn).choice, ActionChoice.done);
  });

  testWidgets('Étapes guidées : le repère d’étape est un simple libellé (Observation / Action / Contrôle), sans pastille', (tester) async {
    await open(tester, sessionState(action: NextActionType.instruction, message: 'Fermez le robinet.'));
    expect(find.text('Action'), findsOneWidget);
    final label = find.ancestor(of: k('phase-label'), matching: find.byType(Container)).first;
    expect(tester.widget<Container>(label).decoration, isNull);
  });

  testWidgets('REQUEST_PHOTO : la zone « À prendre » ouvre la caméra comme le CTA', (tester) async {
    await open(tester, sessionState(action: NextActionType.requestPhoto, message: 'Une photo du raccord.', mediaId: 'm0'));
    expect(find.text('À prendre'), findsOneWidget);
    expect(k('take-requested-photo'), findsOneWidget);
  });
}
