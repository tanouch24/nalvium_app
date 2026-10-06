import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/domain/diagnosis.dart';
import 'package:nalvium/domain/equipment.dart';
import 'package:nalvium/services/photo_capture_service.dart';

import 'helpers/fake_home.dart';
import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

const _small = Size(960, 1704); // 320×568 dp
const _samsung = Size(720, 1600); // 360×800 dp (DPR 2)
const _long = 'Lave-vaisselle encastrable de la cuisine du rez-de-chaussée, côté fenêtre';

Finder k(String key) => find.byKey(Key(key));

/// Fait défiler jusqu'à l'élément (même sous le pli) puis le touche : un bouton inaccessible fait échouer le test.
Future<void> tapK(WidgetTester t, String key) async {
  await seeK(t, key);
  await t.tap(k(key));
  await t.pumpAndSettle();
}

Future<void> seeK(WidgetTester t, String key) async {
  if (k(key).evaluate().isEmpty) {
    // ListView : les éléments sous le pli ne sont construits qu'au défilement.
    final scrollable = find.byType(Scrollable).first;
    try {
      await t.scrollUntilVisible(k(key), 300, scrollable: scrollable);
    } on StateError {
      await t.scrollUntilVisible(k(key), -300, scrollable: scrollable);
    }
  }
  await t.ensureVisible(k(key));
  await t.pumpAndSettle();
}

FakeHomeRepository filled() => FakeHomeRepository(
  items: [
    equipment(id: 'a', name: _long, brand: 'Bosch Siemens Électroménager', model: 'SMS46AI01E/XL', diagnostics: 12),
    equipment(id: 'b', type: 'water_heater', name: 'Chauffe-eau', room: 'bathroom', brand: 'Atlantic', diagnostics: 1),
    equipment(id: 'c', type: 'light', name: 'Luminaire', room: null),
  ],
  diagnostics: {
    'a': [
      EquipmentDiagnostic(id: 's1', status: 'resolved', title: 'Ne vidange plus depuis ce matin malgré le nettoyage du filtre', updatedAt: DateTime(2020, 3, 12)),
      EquipmentDiagnostic(id: 's2', status: 'stopped', title: null, updatedAt: DateTime(2020, 2, 1)),
    ],
  },
);

void main() {
  for (final (size, dpr, name) in [(_small, 3.0, '320 dp'), (_samsung, 2.0, '360×800')]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      group('$name · texte ×$scale', () {
        Future<void> pump(WidgetTester t, {FakeHomeRepository? home, FakeSessionsRepository? repo, String location = '/home', List<Object?> captures = const [null]}) =>
            pumpApp(t, home: home ?? filled(), repo: repo, size: size, dpr: dpr, textScale: scale, location: location, captures: captures);

        testWidgets('Maison vide', (t) async {
          await pump(t, home: FakeHomeRepository(), location: '/house');
          expect(t.takeException(), isNull);
          expect(k('house-add'), findsOneWidget);
        });
        testWidgets('Maison remplie (noms longs, sans pièce)', (t) async {
          await pump(t, location: '/house');
          expect(t.takeException(), isNull);
          await seeK(t, 'house-add');
          expect(t.takeException(), isNull);
        });
        testWidgets('ajout : type, pièce, précisions', (t) async {
          await pump(t, location: '/equipment/add');
          expect(t.takeException(), isNull);
          await seeK(t, 'kind-other');
          await tapK(t, 'kind-other');
          expect(t.takeException(), isNull);
          await seeK(t, 'room-other');
          await tapK(t, 'room-other');
          expect(t.takeException(), isNull);
          await t.enterText(k('field-name'), _long);
          await seeK(t, 'add-save');
          expect(t.takeException(), isNull);
        });
        testWidgets('fiche équipement + feuille de suppression + feuille de diagnostic', (t) async {
          await pump(t, location: '/equipment/a');
          expect(t.takeException(), isNull);
          await seeK(t, 'equipment-delete');
          await tapK(t, 'equipment-delete');
          expect(t.takeException(), isNull);
          await tapK(t, 'delete-cancel');
          await seeK(t, 'equipment-diagnose');
          await tapK(t, 'equipment-diagnose');
          expect(t.takeException(), isNull);
          expect(k('diagnose-film'), findsOneWidget);
        });
        testWidgets('modification', (t) async {
          await pump(t, location: '/equipment/a');
          await seeK(t, 'equipment-edit');
          await tapK(t, 'equipment-edit');
          expect(t.takeException(), isNull);
          await seeK(t, 'edit-save');
          expect(t.takeException(), isNull);
        });
        testWidgets('identification : résultat prudent avec modèle lisible', (t) async {
          final home = filled()
            ..identification = const EquipmentIdentification(
              equipmentType: 'dishwasher', brand: 'Bosch Siemens Électroménager', model: 'SMS46AI01E/XL', confidence: 0.7, visibleText: ['BOSCH', 'SMS46AI01E/XL'],
            );
          await pump(t, home: home, location: '/equipment/identify', captures: [CapturedPhoto(tempPhotoPath('lay'))]);
          await tapK(t, 'identify-take');
          expect(t.takeException(), isNull);
          await seeK(t, 'identify-correct');
          expect(t.takeException(), isNull);
        });
        testWidgets('rattachement d’un diagnostic', (t) async {
          final home = filled()..suggested = EquipmentSuggestions(detectedType: 'dishwasher', matches: [filled().items.first]);
          final repo = FakeSessionsRepository(stored: sessionState(id: 'r1', action: NextActionType.resolved, status: 'resolved', message: 'Réglé.'));
          await pump(t, home: home, repo: repo, location: '/session/r1/house');
          expect(t.takeException(), isNull);
          await seeK(t, 'link-new');
          expect(t.takeException(), isNull);
        });
      });
    }
  }

  testWidgets('cibles tactiles ≥ 48 dp sur la Maison', (t) async {
    await pumpApp(t, home: filled(), size: _small, textScale: 1.0, location: '/house');
    expect(t.getSize(k('house-add-icon')).height, greaterThanOrEqualTo(48));
    expect(t.getSize(k('house-add-icon')).width, greaterThanOrEqualTo(48));
    expect(t.getSize(k('equipment-a')).height, greaterThanOrEqualTo(48));
    await seeK(t, 'house-add');
    expect(t.getSize(k('house-add')).height, greaterThanOrEqualTo(48));
  });

  testWidgets('Reduce Motion : la Maison s’affiche sans animation bloquante', (t) async {
    await pumpApp(t, home: filled(), size: _samsung, dpr: 2, reduceMotion: true, location: '/house');
    expect(t.takeException(), isNull);
    expect(k('equipment-a'), findsOneWidget);
  });

  testWidgets('lecteur d’écran : ligne d’équipement décrite en une phrase, état jamais seulement visuel', (t) async {
    final handle = t.ensureSemantics();
    await pumpApp(t, home: filled(), location: '/house');
    expect(find.bySemanticsLabel(RegExp(r'Chauffe-eau\. Atlantic\. 1 diagnostic')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'Luminaire\. Marque non renseignée\. Aucun problème')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('lecteur d’écran : étapes et titre en-tête dans le flux d’ajout', (t) async {
    final handle = t.ensureSemantics();
    await pumpApp(t, home: FakeHomeRepository(), location: '/equipment/add');
    expect(t.getSemantics(k('add-step-title')), matchesSemantics(label: 'Quel équipement ?', isHeader: true));
    handle.dispose();
  });
}
