import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/domain/diagnosis.dart';
import 'package:nalvium/domain/session.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

Finder k(String key) => find.byKey(Key(key));

const _longResolved =
    'Parfait, la fuite est stoppée et le siphon reste parfaitement sec depuis plusieurs minutes. Surveillez pendant 24 h et resserrez à la main si besoin ; si ça revient, on envisagera le joint. Bonne nouvelle !';

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
  bool reduceMotion = false,
  List<Object> turns = const [],
}) async {
  final repo = FakeSessionsRepository(stored: state, turns: turns);
  await pumpApp(tester, repo: repo, location: '/session/s1', size: size, dpr: dpr, textScale: scale, reduceMotion: reduceMotion);
  return repo;
}

Future<void> reach(WidgetTester tester, String key) async {
  await tester.scrollUntilVisible(k(key), 120, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(k(key));
  await tester.pump();
  expect(tester.getSize(k(key)).height, greaterThanOrEqualTo(48), reason: key);
}

void main() {
  for (final cfg in _configs) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('RESOLVED ${cfg.$1} · ×$scale : texte long, CTA accessibles, sans overflow', (tester) async {
        await open(tester, sessionState(action: NextActionType.resolved, message: _longResolved, status: 'resolved'), size: cfg.$2, dpr: cfg.$3, scale: scale);
        expect(tester.takeException(), isNull);
        expect(k('resolved-title'), findsOneWidget);
        for (final key in ['resolved-finish', 'resolved-summary']) {
          await reach(tester, key);
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('SAFETY_STOP ${cfg.$1} · ×$scale : danger et action sûre toujours présents et atteignables', (tester) async {
        await open(
          tester,
          sessionState(action: NextActionType.safetyStop, message: 'Arrêtez-vous ici. Une fuite de gaz peut provoquer une explosion ou une intoxication. Aérez, n\'actionnez aucun interrupteur, sortez, puis appelez le 112 ou votre fournisseur.', status: 'stopped'),
          size: cfg.$2,
          dpr: cfg.$3,
          scale: scale,
        );
        expect(tester.takeException(), isNull);
        expect(k('safety-title'), findsOneWidget);
        expect(find.textContaining('appelez le 112'), findsOneWidget);
        for (final key in ['safety-find-pro', 'safety-understood']) {
          await reach(tester, key);
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('RECOMMEND_PROFESSIONAL ${cfg.$1} · ×$scale : raison visible, CTA accessibles', (tester) async {
        await open(
          tester,
          sessionState(action: NextActionType.recommendProfessional, message: 'Le raccord est fissuré au niveau du mur : il faut remplacer la pièce, ce qui demande des outils et un savoir-faire adaptés.'),
          size: cfg.$2,
          dpr: cfg.$3,
          scale: scale,
        );
        expect(tester.takeException(), isNull);
        expect(find.textContaining('Le raccord est fissuré'), findsOneWidget);
        for (final key in ['see-repair-options', 'pro-home']) {
          await reach(tester, key);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('RESOLVED : aucune ponctuation seule (espace insécable avant « ! » et « ; »)', (tester) async {
    await open(tester, sessionState(action: NextActionType.resolved, message: _longResolved, status: 'resolved'));
    final shown = tester.widget<Text>(k('nalvium-message')).data!;
    expect(shown.contains(' !'), isFalse);
    expect(shown.contains(' ;'), isFalse);
    expect(shown.contains(' !'), isTrue);
    expect(shown.replaceAll(' ', ' '), _longResolved); // le texte reçu n'est pas altéré
  });

  testWidgets('RECOMMEND_PROFESSIONAL : aucune promesse de professionnel ni de disponibilité', (tester) async {
    await open(tester, sessionState(action: NextActionType.recommendProfessional, message: 'Cette intervention nécessite un professionnel.'));
    final all = find.byType(Text).evaluate().map((e) => (e.widget as Text).data ?? '').join(' ').toLowerCase();
    for (final promise in ['réservé', 'garanti', 'disponible', 'arrive', 'en route', 'confirmé']) {
      expect(all.contains(promise), isFalse, reason: promise);
    }
    expect(k('see-repair-options'), findsOneWidget);
    expect(k('pro-home'), findsOneWidget);
  });

  testWidgets('SAFETY_STOP : fond d’alerte et actions inchangées (Demander de l’aide, Compris)', (tester) async {
    await open(tester, sessionState(action: NextActionType.safetyStop, message: 'Arrêtez-vous ici. Coupez le courant.', status: 'stopped'));
    expect(find.text('Arrêtez-vous ici'), findsOneWidget);
    expect(find.text('Coupez le courant.'), findsOneWidget);
    expect(find.text('Demander de l\'aide'), findsWidgets);
    expect(k('safety-understood'), findsOneWidget);
  });

  testWidgets('ATTENTE interne : variant léger « Je prépare la suite… », Annuler ≥ 48 dp, résultat inchangé', (tester) async {
    final repo = await open(
      tester,
      sessionState(message: 'Question ?', choices: ['Oui', 'Non']),
      turns: [sessionState(action: NextActionType.instruction, message: 'Fermez le robinet.', messages: 4)],
    )
      ..turnGate = Completer<void>();
    await tester.tap(k('choice-Oui'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Je prépare la suite…'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    expect(tester.getSize(k('cancel-analysis')).height, greaterThanOrEqualTo(48));
    repo.turnGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Fermez le robinet.'), findsOneWidget); // même réponse du diagnostic qu'avant
  });

  testWidgets('ATTENTE interne : « Réduire les animations » → pas de boucle, aucun overflow à ×2 sur 320 dp', (tester) async {
    final repo = await open(
      tester,
      sessionState(message: 'Question ?', choices: ['Oui', 'Non']),
      size: const Size(960, 1704),
      dpr: 3,
      scale: 2.0,
      reduceMotion: true,
      turns: [sessionState(action: NextActionType.instruction, message: 'Fermez le robinet.', messages: 4)],
    )
      ..turnGate = Completer<void>();
    await tester.ensureVisible(k('choice-Oui'));
    await tester.pump();
    await tester.tap(k('choice-Oui'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    expect(find.text('Je prépare la suite…'), findsOneWidget);
    repo.turnGate!.complete();
    await tester.pumpAndSettle();
  });
}
