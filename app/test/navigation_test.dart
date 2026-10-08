import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('la barre affiche Accueil | Ma maison | Historique + Scanner', (tester) async {
    await pumpApp(tester);
    for (final label in ['Accueil', 'Ma maison', 'Historique']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byKey(const Key('nav-camera')), findsOneWidget);
    expect(find.text('Communauté'), findsNothing);
    expect(find.text('Dépannage'), findsNothing);
  });

  testWidgets('Ma maison et Historique affichent un état vide honnête ; les artisans s\'ouvrent depuis l\'Historique', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('nav-house')));
    await tester.pumpAndSettle();
    // Phase 4 : l'onglet Maison est une vraie expérience (état vide invitant, pas un faux contenu).
    expect(find.text('Votre maison'), findsOneWidget);
    expect(find.byKey(const Key('house-add')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-history')));
    await tester.pumpAndSettle();
    expect(find.text('Aucun historique'), findsOneWidget);
    await tester.tap(find.byKey(const Key('history-repair')));
    await tester.pumpAndSettle();
    expect(find.text("Besoin d'un coup de main ?"), findsOneWidget);
    expect(find.byKey(const Key('repair-empty')), findsOneWidget); // aucune fausse demande
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

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

  testWidgets('Réglages s\'ouvrent depuis l\'accueil', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('open-settings')));
    await tester.pumpAndSettle();
    expect(find.text('Réglages'), findsWidgets);
  });
}
