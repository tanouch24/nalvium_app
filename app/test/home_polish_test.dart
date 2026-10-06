import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

Finder k(String key) => find.byKey(Key(key));

void main() {
  for (final scale in [1.0, 1.5, 2.0]) {
    for (final withSession in [false, true]) {
      testWidgets('Accueil 320 dp · ×$scale · ${withSession ? 'avec' : 'sans'} reprise : aucun overflow, cibles ≥ 48 dp', (tester) async {
        final repo = withSession
            ? FakeSessionsRepository(sessions: [summary(title: 'Lave-vaisselle', state: 'INSTRUCTION', lastMessage: 'Vérifiez maintenant le filtre du lave-vaisselle')])
            : null;
        await pumpApp(tester, repo: repo, size: const Size(960, 2400), dpr: 3, textScale: scale);
        expect(tester.takeException(), isNull);
        for (final key in ['open-history', 'open-settings', 'describe-problem', 'film-problem', 'take-photo']) {
          await tester.scrollUntilVisible(k(key), 100, scrollable: find.byType(Scrollable).first);
          expect(k(key), findsOneWidget, reason: key);
          final size = tester.getSize(k(key));
          expect(size.width, greaterThanOrEqualTo(48), reason: key);
          expect(size.height, greaterThanOrEqualTo(48), reason: key);
        }
        if (withSession) {
          await tester.scrollUntilVisible(k('resume-session'), 200, scrollable: find.byType(Scrollable).first);
          expect(tester.getSize(k('resume-session')).height, greaterThanOrEqualTo(48));
        }
      });
    }
  }

  testWidgets('Décrire et Filmer : même hauteur, même largeur', (tester) async {
    await pumpApp(tester);
    final a = tester.getSize(k('describe-problem'));
    final b = tester.getSize(k('film-problem'));
    expect(a.height, b.height);
    expect(a.width, b.width);
  });

  testWidgets('×2 : Décrire et Filmer s\'empilent à la même largeur et hauteur', (tester) async {
    await pumpApp(tester, size: const Size(960, 2400), dpr: 3, textScale: 2.0);
    await tester.scrollUntilVisible(k('film-problem'), 100, scrollable: find.byType(Scrollable).first);
    final a = tester.getSize(k('describe-problem'));
    final b = tester.getSize(k('film-problem'));
    expect(a, b);
    expect(tester.getTopLeft(k('film-problem')).dy, greaterThan(tester.getTopLeft(k('describe-problem')).dy));
  });

  testWidgets('aucun libellé de bannière de test en dehors du mode test de mise en page', (tester) async {
    await pumpApp(tester);
    expect(find.textContaining('Espace publicitaire'), findsNothing);
  });
}
