import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('la barre affiche Accueil | Maison | Caméra | Dépannage | Communauté', (tester) async {
    await pumpApp(tester);
    for (final label in ['Accueil', 'Maison', 'Dépannage', 'Communauté']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byKey(const Key('nav-camera')), findsOneWidget);
  });

  testWidgets('les onglets Maison, Dépannage, Communauté affichent un état vide honnête', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('nav-house')));
    await tester.pumpAndSettle();
    expect(find.text('Votre maison prendra forme ici'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-repair')));
    await tester.pumpAndSettle();
    expect(find.text('Aucune demande en cours'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-community')));
    await tester.pumpAndSettle();
    expect(find.text('Les réparations des autres, bientôt ici'), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-home')));
    await tester.pumpAndSettle();
    expect(find.text('Un problème à la maison ?'), findsOneWidget);
  });

  testWidgets('le bouton caméra n\'est pas un onglet : il ne change pas de page', (tester) async {
    final fake = await pumpApp(tester); // annulation
    await tester.tap(find.byKey(const Key('nav-camera')));
    await tester.pumpAndSettle();
    expect(fake.calls, 1);
    expect(find.text('Un problème à la maison ?'), findsOneWidget);
  });

  testWidgets('Historique et Réglages s\'ouvrent depuis l\'accueil', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('open-history')));
    await tester.pumpAndSettle();
    expect(find.text('Aucun historique'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Réglages'), findsWidgets);
  });
}
