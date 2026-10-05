import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/core/widgets/choice_tile.dart';
import 'package:nalvium/core/widgets/viewfinder.dart';
import 'package:nalvium/domain/diagnosis.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

Future<FakeSessionsRepository> openSession(WidgetTester tester, SessionStateLike s, {Size size = const Size(1080, 2800), double scale = 1}) async {
  final repo = FakeSessionsRepository(stored: s);
  await pumpApp(tester, repo: repo, location: '/session/s1', size: size, textScale: scale);
  return repo;
}

typedef SessionStateLike = dynamic;

void main() {
  group('ANALYSE sans photo : variante compacte', () {
    testWidgets('titre dédié + rappel de la description, sans zone d\'image', (tester) async {
      final repo = FakeSessionsRepository(turns: [sessionState()])..turnGate = Completer<void>();
      await pumpApp(tester, repo: repo);
      await tester.tap(find.byKey(const Key('describe-problem')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('describe-field')), 'Mon lave-vaisselle ne vidange plus');
      await tester.pump();
      await tester.tap(find.byKey(const Key('describe-continue')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('J\'analyse votre description…'), findsOneWidget);
      expect(find.byKey(const Key('analysis-subject')), findsOneWidget);
      expect(find.textContaining('Mon lave-vaisselle ne vidange plus'), findsOneWidget);
      // variante compacte : le cadre fait ~124 dp au lieu de ~276×336 pour une photo
      final frame = tester.getSize(find.descendant(of: find.byType(Center).first, matching: find.byType(ViewfinderCorners)).first);
      expect(frame.width, lessThan(150));
      expect(tester.takeException(), isNull);
      repo.turnGate!.complete();
      await tester.pumpAndSettle();
    });
  });

  group('GUIDAGE : structure commune', () {
    for (final a in [NextActionType.askQuestion, NextActionType.instruction, NextActionType.verification]) {
      testWidgets('contexte constant : vignette+titre+catégorie sur ${a.name}', (tester) async {
        await openSession(tester, sessionState(action: a, message: 'Message', mediaId: 'm1', category: 'plumbing', choices: const []));
        expect(find.byKey(const Key('context-title')), findsOneWidget);
        expect(find.byKey(const Key('category-label')), findsOneWidget);
        expect(find.text('Plomberie'), findsOneWidget);
        expect(find.byKey(const Key('phase-label')), findsOneWidget);
        expect(find.byKey(const Key('guidance-title')), findsOneWidget);
        expect(find.byKey(const Key('nalvium-message')), findsOneWidget);
      });
    }

    testWidgets('la question est le héros : plus grande que son titre d\'état et que les réponses', (tester) async {
      await openSession(tester, sessionState(message: 'Le câble est-il branché ?', choices: ['Oui', 'Non']));
      final hero = tester.widget<Text>(find.byKey(const Key('nalvium-message'))).style!.fontSize!;
      final state = tester.widget<Text>(find.byKey(const Key('guidance-title'))).style!.fontSize!;
      expect(hero, greaterThan(state));
      expect(hero, greaterThanOrEqualTo(24));
    });

    testWidgets('INSTRUCTION : l\'action est le héros (grande, trait d\'accent), boutons hiérarchisés', (tester) async {
      await openSession(tester, sessionState(action: NextActionType.instruction, message: 'Resserrez l\'écrou à la main.', items: const ['Chiffon']));
      expect(tester.widget<Text>(find.byKey(const Key('nalvium-message'))).style!.fontSize, greaterThanOrEqualTo(24));
      final done = tester.getSize(find.byKey(const Key('action-done'))).height;
      expect(done, greaterThanOrEqualTo(56));
      expect(find.text('Chiffon'), findsOneWidget); // matériel réel du backend, en pastille discrète
    });

    testWidgets('REQUEST_PHOTO : photo précédente → vue demandée', (tester) async {
      await openSession(tester, sessionState(action: NextActionType.requestPhoto, message: 'Photographiez le raccord.', mediaId: 'm1'));
      expect(find.text('Votre photo'), findsOneWidget);
      expect(find.text('À prendre'), findsOneWidget);
      expect(find.byKey(const Key('photo-target')), findsOneWidget);
      expect(find.byKey(const Key('context-title')), findsNothing); // la paire remplace l'en-tête
    });

    testWidgets('REQUEST_PHOTO sans photo précédente (session texte) : seulement la vue demandée', (tester) async {
      await openSession(tester, sessionState(action: NextActionType.requestPhoto, message: 'Photographiez le raccord.'));
      expect(find.text('Votre photo'), findsNothing);
      expect(find.text('À prendre'), findsOneWidget);
    });

    testWidgets('VERIFICATION : quatre résultats en grille 2×2 avec icônes', (tester) async {
      await openSession(tester, sessionState(action: NextActionType.verification, message: 'L\'eau s\'évacue-t-elle ?'));
      final tiles = find.byType(ChoiceTile);
      expect(tiles, findsNWidgets(4));
      final p0 = tester.getTopLeft(tiles.at(0)), p1 = tester.getTopLeft(tiles.at(1)), p2 = tester.getTopLeft(tiles.at(2));
      expect(p1.dy, p0.dy); // 1re ligne : Oui | Un peu
      expect(p2.dy, greaterThan(p0.dy)); // 2e ligne : Non | Je ne sais pas
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.descendant(of: tiles.at(2), matching: find.byIcon(Icons.close_rounded)), findsOneWidget);
    });

    testWidgets('ASK_QUESTION : icônes seulement si toutes les réponses en ont (cohérence)', (tester) async {
      await openSession(tester, sessionState(message: 'Q ?', choices: const ['Uniquement quand l\'eau coule', 'Même sans utiliser l\'évier', 'Je ne sais pas']));
      expect(find.byIcon(Icons.help_outline_rounded), findsNothing);
    });

    testWidgets('ASK_QUESTION : Oui / Non gardent leurs icônes', (tester) async {
      await openSession(tester, sessionState(message: 'Q ?', choices: const ['Oui', 'Non']));
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('VERIFICATION : réponses inhabituelles du backend → liste simple', (tester) async {
      await openSession(tester, sessionState(action: NextActionType.verification, message: 'Quel est le débit ?', choices: const ['Fort', 'Faible']));
      expect(find.byType(ChoiceTile), findsNWidgets(2));
    });

    testWidgets('ChoiceTile : état pressé visible (fond/bordure bleus) et tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(child: ChoiceTile(label: 'Oui', onTap: () => taps++)))));
      final before = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration as BoxDecoration;
      final g = await tester.startGesture(tester.getCenter(find.text('Oui')));
      await tester.pump(const Duration(milliseconds: 200));
      final during = tester.widget<AnimatedContainer>(find.byType(AnimatedContainer)).decoration as BoxDecoration;
      expect(during.color, isNot(before.color));
      await g.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
    });
  });

  group('RESOLVED', () {
    testWidgets('titre, problème résolu, conclusion et CTA ; animation terminée sans erreur', (tester) async {
      await openSession(tester, sessionState(action: NextActionType.resolved, message: 'Le filtre était bouché.', status: 'resolved', title: 'Lave-vaisselle'));
      await tester.pumpAndSettle();
      expect(find.text('C\'est réglé'), findsOneWidget);
      expect(find.byKey(const Key('resolved-problem')), findsOneWidget);
      expect(find.text('Lave-vaisselle'), findsOneWidget);
      expect(find.text('Le filtre était bouché.'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('« Réduire les animations » : le contenu est visible immédiatement', (tester) async {
      final repo = FakeSessionsRepository(stored: sessionState(action: NextActionType.resolved, message: 'Réglé.', status: 'resolved'));
      await pumpApp(tester, repo: repo, location: '/session/s1', reduceMotion: true);
      final opacity = tester.widget<FadeTransition>(find.ancestor(of: find.byKey(const Key('resolved-title')), matching: find.byType(FadeTransition)).first).opacity.value;
      expect(opacity, 1);
    });
  });

  testWidgets('NAVIGATION : l\'onglet actif a un indicateur, pas les autres', (tester) async {
    await pumpApp(tester);
    Color? bg(String key) {
      final c = tester.widget<AnimatedContainer>(find.descendant(of: find.byKey(Key(key)), matching: find.byType(AnimatedContainer)));
      return (c.decoration as BoxDecoration).color;
    }

    expect(bg('nav-home'), isNot(Colors.transparent));
    expect(bg('nav-house'), Colors.transparent);
    await tester.tap(find.byKey(const Key('nav-house')));
    await tester.pumpAndSettle();
    expect(bg('nav-house'), isNot(Colors.transparent));
    expect(bg('nav-home'), Colors.transparent);
  });
}
