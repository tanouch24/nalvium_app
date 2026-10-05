import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

void main() {
  testWidgets('HOME sans session : explique l\'app, aucune section ni faux contenu', (tester) async {
    await pumpApp(tester);
    expect(find.text('NALVIUM'), findsOneWidget);
    expect(find.text('Bonjour'), findsOneWidget);
    expect(find.text('Un problème à la maison ?'), findsOneWidget);
    expect(find.textContaining('Montrez-le à Nalvium.'), findsOneWidget);
    expect(find.text('Prendre une photo'), findsOneWidget);
    expect(find.text('Le moyen le plus rapide'), findsOneWidget);
    expect(find.text('Décrire'), findsOneWidget);
    expect(find.text('Filmer'), findsOneWidget);
    expect(find.text('Bientôt'), findsNothing); // Filmer est désormais une vraie fonction

    expect(find.text('À reprendre'), findsNothing);
    expect(find.byKey(const Key('resume-session')), findsNothing);
    for (final fake in ['Votre maison', 'Conseil du jour', 'Astuce', 'Statistiques']) {
      expect(find.textContaining(fake), findsNothing);
    }
  });

  testWidgets('HOME avec session active : UNE carte réelle (titre, catégorie, dernière étape, Continuer)', (tester) async {
    final repo = FakeSessionsRepository(sessions: [
      summary(title: 'Lave-vaisselle', state: 'INSTRUCTION', category: 'appliance', lastMessage: 'Vérifiez maintenant le filtre'),
      summary(id: 's2', title: 'Autre session active', state: 'ASK_QUESTION'),
    ]);
    await pumpApp(tester, repo: repo);
    expect(find.text('À reprendre'), findsOneWidget);
    expect(find.text('Lave-vaisselle'), findsOneWidget);
    expect(find.byKey(const Key('resume-last')), findsOneWidget); // la dernière question/action, telle quelle
    expect(find.text('Vérifiez maintenant le filtre'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
    expect(find.textContaining('Électroménager'), findsNothing); // métadonnées secondaires réduites
    expect(find.textContaining('Aujourd\'hui'), findsOneWidget);
    expect(find.byKey(const Key('resume-session')), findsOneWidget); // une seule carte
    expect(find.text('Autre session active'), findsNothing);
  });

  testWidgets('la photo est l\'action principale : plus haute que Décrire et Filmer', (tester) async {
    await pumpApp(tester);
    final photo = tester.getSize(find.byKey(const Key('take-photo')));
    final describe = tester.getSize(find.byKey(const Key('describe-problem')));
    final film = tester.getSize(find.byKey(const Key('film-problem')));
    expect(photo.height, greaterThan(describe.height * 2.5));
    expect(photo.width, greaterThan(describe.width));
    expect(film.width, lessThanOrEqualTo(describe.width));
  });
}
