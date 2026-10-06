import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/domain/equipment.dart';

import 'helpers/fake_home.dart';
import 'helpers/pump_app.dart';

Finder k(String key) => find.byKey(Key(key));

FakeHomeRepository two() => FakeHomeRepository(
  items: [
    equipment(id: 'a', name: 'Lave-vaisselle', brand: 'Bosch', model: 'SMS46', diagnostics: 2),
    equipment(id: 'b', type: 'water_heater', name: 'Chauffe-eau', room: 'bathroom', brand: 'Atlantic'),
  ],
  diagnostics: {
    'a': [
      EquipmentDiagnostic(id: 's1', status: 'resolved', title: 'Fuite sous le siphon', updatedAt: DateTime(2020, 3, 12)),
      EquipmentDiagnostic(id: 's2', status: 'active', title: 'Ne vidange plus', updatedAt: DateTime(2020, 3, 14)),
    ],
  },
);

void main() {
  testWidgets('MAISON vide : composition compacte, CTA unique et visible sans défiler (Samsung ×1)', (tester) async {
    await pumpApp(tester, home: FakeHomeRepository(), location: '/house');
    expect(k('house-empty-body'), findsOneWidget);
    expect(find.byKey(const Key('house-add')), findsOneWidget);
    final screen = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(tester.getRect(k('house-add')).bottom, lessThan(screen));
    expect(tester.getSize(k('house-add')).height, greaterThanOrEqualTo(48));
    expect(find.text('Lave-vaisselle'), findsNothing); // aucun faux équipement
  });

  testWidgets('MAISON remplie : plusieurs pièces, cartes compactes et scannables', (tester) async {
    await pumpApp(tester, home: two(), location: '/house');
    expect(find.text('Cuisine'), findsWidgets);
    expect(find.text('Salle de bain'), findsWidgets);
    final a = tester.getSize(k('equipment-a'));
    expect(a.height, lessThan(120)); // pas de grosse carte (police de test plus haute que la vraie)
    expect(a.height, greaterThanOrEqualTo(48));
    // la carte d'un équipement ouvre toujours sa fiche
    await tester.tap(k('equipment-a'));
    await tester.pumpAndSettle();
    expect(k('equipment-name'), findsOneWidget);
  });

  testWidgets('FICHE : identité, infos, diagnostics liés en cartes, actions secondaires — rien d\'inventé', (tester) async {
    await pumpApp(tester, home: two(), location: '/equipment/a');
    expect(find.text('Lave-vaisselle'), findsWidgets);
    expect(find.text('Bosch'), findsOneWidget);
    expect(find.textContaining('SMS46'), findsOneWidget);
    expect(k('equipment-diagnose'), findsOneWidget);
    await tester.scrollUntilVisible(k('equipment-diag-s1'), 200, scrollable: find.byType(Scrollable).first);
    expect(tester.getSize(k('equipment-diag-s1')).height, greaterThanOrEqualTo(48));
    final all = find.byType(Text).evaluate().map((e) => (e.widget as Text).data ?? '').join(' ').toLowerCase();
    for (final invented in ['garantie', 'maintenance', 'score', 'consommation', 'santé']) {
      expect(all.contains(invented), isFalse, reason: invented);
    }
  });

  testWidgets('AJOUT : le chemin photo est un grand bloc tactile ; les tuiles de type suivent la même famille', (tester) async {
    await pumpApp(tester, home: FakeHomeRepository(), location: '/equipment/add');
    expect(tester.getSize(k('add-identify')).height, greaterThanOrEqualTo(56));
    expect(k('add-search'), findsOneWidget);
    await tester.tap(k('kind-dishwasher'));
    await tester.pumpAndSettle();
    await tester.tap(k('room-kitchen'));
    await tester.pumpAndSettle();
    expect(k('field-brand'), findsOneWidget);
    expect(k('add-save'), findsOneWidget); // champs facultatifs : on peut enregistrer sans les remplir
  });

  for (final scale in [1.0, 1.5, 2.0]) {
    testWidgets('AJOUT 320 dp · ×$scale : aucun overflow sur l\'étape type', (tester) async {
      await pumpApp(tester, home: FakeHomeRepository(), location: '/equipment/add', size: const Size(960, 1704), dpr: 3, textScale: scale);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(k('add-identify')).height, greaterThanOrEqualTo(48));
    });
  }
}
