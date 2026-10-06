import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_community.dart';
import 'helpers/pump_app.dart';

Finder k(String key) => find.byKey(Key(key));

Future<void> open(WidgetTester t, FakeCommunityRepository repo, String location, {Size size = const Size(1080, 4800), double scale = 1.0, double dpr = 3}) =>
    pumpApp(t, community: repo, location: location, size: size, dpr: dpr, textScale: scale);

String allText(WidgetTester t) => find.byType(Text).evaluate().map((e) => (e.widget as Text).data ?? '').join(' ').toLowerCase();

void main() {
  testWidgets('FIL vide : explication simple + CTA, aucun faux post', (tester) async {
    await open(tester, FakeCommunityRepository(), '/community');
    expect(k('community-empty'), findsOneWidget);
    expect(k('community-empty-share'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
    expect(allText(tester).contains('avatar'), isFalse);
  });

  testWidgets('FIL : carte problème → solution, aucune métrique sociale inventée', (tester) async {
    await open(tester, FakeCommunityRepository(posts: [makePost(id: 'a', photo: 'p1', materials: 'Clé à molette')]), '/community');
    final title = tester.getTopLeft(find.text('Mon lave-vaisselle ne vidangeait plus')).dy;
    final solution = tester.getTopLeft(find.textContaining("J'ai nettoyé le filtre")).dy;
    expect(title, lessThan(solution));
    final all = allText(tester);
    for (final social in ['abonné', 'follower', 'vues', 'badge', 'populaire', 'partager avec']) {
      expect(all.contains(social), isFalse, reason: social);
    }
  });

  testWidgets('DÉTAIL : problème, puis photo, puis solution ; Signaler discret mais ≥ 48 dp', (tester) async {
    await open(tester, FakeCommunityRepository(posts: [makePost(id: 'a', photo: 'p1', materials: 'Clé à molette')]), '/community/post/a');
    final title = tester.getTopLeft(k('post-title')).dy;
    final photo = tester.getTopLeft(k('post-photo')).dy;
    final solution = tester.getTopLeft(k('post-solution')).dy;
    expect(title, lessThan(photo));
    expect(photo, lessThan(solution));
    await tester.scrollUntilVisible(k('detail-report'), 200, scrollable: find.byType(Scrollable).first);
    expect(tester.getSize(k('detail-report')).height, greaterThanOrEqualTo(48));
    expect(tester.getTopLeft(k('detail-report')).dx, greaterThan(tester.getTopLeft(k('detail-helpful')).dx)); // à droite des actions utiles
  });

  testWidgets('CRÉATION : problème et solution d’abord, la photo et les infos facultatives ensuite', (tester) async {
    await open(tester, FakeCommunityRepository(), '/community/new');
    final title = tester.getTopLeft(k('compose-title')).dy;
    final solution = tester.getTopLeft(k('compose-solution')).dy;
    final photo = tester.getTopLeft(k('compose-take-photo')).dy;
    final category = tester.getTopLeft(k('compose-cat-plumbing')).dy;
    final materials = tester.getTopLeft(k('compose-materials')).dy;
    expect(title, lessThan(solution));
    expect(solution, lessThan(photo));
    expect(photo, lessThan(category));
    expect(category, lessThan(materials));
    expect(k('compose-review'), findsOneWidget);
  });

  testWidgets('APERÇU : dit que seul l’aperçu sera publié ; consentement non précoché dans sa surface ; aucune donnée privée', (tester) async {
    await open(tester, FakeCommunityRepository(), '/community/new');
    await tester.enterText(k('compose-title'), 'Robinet qui goutte');
    await tester.enterText(k('compose-solution'), "J'ai changé le joint du robinet.");
    await tester.scrollUntilVisible(k('compose-continue'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(k('compose-continue'));
    await tester.pumpAndSettle();
    expect(k('preview-note'), findsOneWidget);
    expect(find.textContaining('Seul ce qui apparaît ci-dessous sera publié'), findsOneWidget);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    expect(find.ancestor(of: k('compose-consent'), matching: find.byType(Material)), findsWidgets);
    final all = allText(tester);
    for (final private in ['téléphone :', 'uuid', 'code postal', 'exif', '+33']) {
      expect(all.contains(private), isFalse, reason: private);
    }
  });

  for (final scale in [1.0, 1.5, 2.0]) {
    for (final loc in ['/community', '/community/post/a', '/community/new']) {
      testWidgets('320 dp · ×$scale · $loc : sans overflow', (tester) async {
        await open(
          tester,
          FakeCommunityRepository(posts: [makePost(id: 'a', photo: 'p1', title: 'Robinet de cuisine qui goutte en continu même fermé à fond depuis plusieurs jours', solution: 'J’ai démonté la cartouche, nettoyé le calcaire et changé le joint torique usé puis tout remonté avec un peu de graisse silicone.', materials: 'Clé à molette, joint torique, graisse silicone')]),
          loc,
          size: const Size(960, 1704),
          scale: scale,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
