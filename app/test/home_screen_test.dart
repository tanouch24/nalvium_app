import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('l\'accueil explique l\'app et ne montre aucun faux contenu', (tester) async {
    await pumpApp(tester);
    expect(find.text('NALVIUM'), findsOneWidget);
    expect(find.text('Bonjour'), findsOneWidget);
    expect(find.text('Un problème à la maison ?'), findsOneWidget);
    expect(find.textContaining('Montrez-le à Nalvium.'), findsOneWidget);
    expect(find.text('Prendre une photo'), findsOneWidget);
    expect(find.text('Décrire le problème'), findsOneWidget);
    expect(find.text('Filmer'), findsOneWidget);

    // Aucune donnée réelle => ces sections n'existent pas.
    expect(find.text('À reprendre'), findsNothing);
    expect(find.text('Votre maison'), findsNothing);
    expect(find.textContaining('Conseil du jour'), findsNothing);
  });

  testWidgets('actions pas encore construites : message honnête', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Filmer'));
    await tester.pump();
    expect(find.text('Bientôt disponible'), findsOneWidget);
  });
}
