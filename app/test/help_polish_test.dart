import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_requests.dart';
import 'helpers/pump_app.dart';

Finder k(String key) => find.byKey(Key(key));

String allText(WidgetTester t) => find.byType(Text).evaluate().map((e) => (e.widget as Text).data ?? '').join(' ').toLowerCase();

const _promises = ['rendez-vous confirmé', 'réservation', 'garanti', 'artisan disponible', 'immédiat', 'sous 24', 'prix', 'tarif', 'gratuit'];

void main() {
  testWidgets('DÉPANNAGE vide : une carte principale, un CTA, aucune fausse donnée', (tester) async {
    await pumpApp(tester, location: '/repair');
    expect(k('repair-headline'), findsOneWidget);
    expect(tester.getSize(k('repair-ask')).height, greaterThanOrEqualTo(48));
    expect(k('repair-empty'), findsOneWidget);
    final all = allText(tester);
    for (final p in _promises) {
      expect(all.contains(p), isFalse, reason: p);
    }
    for (final fake in ['noté', 'avis', 'étoile', 'disponibles près']) {
      expect(all.contains(fake), isFalse, reason: fake);
    }
  });

  testWidgets('DÉPANNAGE rempli : cartes de demandes, statut réel, sans suivi inventé', (tester) async {
    await pumpApp(
      tester,
      requests: FakeServiceRequestsRepository(items: [request(id: 'a', summary: 'Lave-vaisselle qui ne vidange plus', equipmentLabel: 'Lave-vaisselle Bosch')]),
      location: '/repair',
    );
    expect(tester.getSize(k('request-a')).height, greaterThanOrEqualTo(48));
    expect(find.text('Demande envoyée'), findsOneWidget);
    expect(find.textContaining('en route'), findsNothing);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('FORMULAIRE : consentement non précoché, dans sa propre surface, et il se coche', (tester) async {
    await pumpApp(tester, requests: FakeServiceRequestsRepository(), location: '/repair', size: const Size(1080, 4800));
    await tester.tap(k('repair-ask'));
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.descendant(of: k('help-consent'), matching: find.byType(Checkbox))).value, isFalse);
    expect(find.ancestor(of: k('help-consent'), matching: find.byType(Material)), findsWidgets);
    await tester.ensureVisible(k('help-consent'));
    await tester.pump();
    await tester.tap(k('help-consent'));
    await tester.pump();
    expect(tester.widget<Checkbox>(find.descendant(of: k('help-consent'), matching: find.byType(Checkbox))).value, isTrue);
    expect(tester.getSize(k('help-consent')).height, greaterThanOrEqualTo(48));
  });

  testWidgets('FORMULAIRE : la disponibilité est une préférence, aucune promesse', (tester) async {
    await pumpApp(tester, requests: FakeServiceRequestsRepository(), location: '/repair', size: const Size(1080, 4800));
    await tester.tap(k('repair-ask'));
    await tester.pumpAndSettle();
    expect(find.text('C\'est une préférence, pas une réservation.'), findsOneWidget);
    final all = allText(tester).replaceAll('pas une réservation', '');
    for (final p in _promises.where((p) => p != 'gratuit')) {
      expect(all.contains(p), isFalse, reason: p);
    }
  });

  testWidgets('DÉTAIL : disponibilité (préférence) avant les coordonnées, aucune donnée interne', (tester) async {
    await pumpApp(tester, requests: FakeServiceRequestsRepository(items: [request(id: 'a', media: const ['m1'])]), location: '/requests/a', size: const Size(1080, 4800));
    final availability = tester.getTopLeft(k('request-availability')).dy;
    final person = tester.getTopLeft(find.textContaining('Camille')).dy;
    expect(availability, lessThan(person));
    final all = allText(tester);
    for (final internal in ['uuid', 'confidence', 'prompt', 'gpt', 'consent_version']) {
      expect(all.contains(internal), isFalse, reason: internal);
    }
    expect(find.textContaining('pas encore transmis votre demande à un professionnel'), findsOneWidget);
  });

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('320 dp · ×$scale : Dépannage rempli et détail sans overflow', (tester) async {
      for (final loc in ['/repair', '/requests/a']) {
        await pumpApp(
          tester,
          requests: FakeServiceRequestsRepository(items: [request(id: 'a', summary: 'Lave-vaisselle qui ne vidange plus depuis ce matin malgré le nettoyage du filtre', equipmentLabel: 'Lave-vaisselle encastrable Bosch Siemens')]),
          location: loc,
          size: const Size(960, 1704),
          dpr: 3,
          textScale: scale,
        );
        expect(tester.takeException(), isNull, reason: loc);
      }
    });
  }
}
