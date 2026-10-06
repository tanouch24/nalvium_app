import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/core/network/api_exceptions.dart';
import 'package:nalvium/domain/diagnosis.dart';
import 'package:nalvium/core/widgets/buttons.dart';
import 'package:nalvium/domain/equipment.dart';
import 'package:nalvium/services/photo_capture_service.dart';

import 'helpers/fake_home.dart';
import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

Future<void> openHouse(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('nav-house')));
  await tester.pumpAndSettle();
}

Finder byKey(String k) => find.byKey(Key(k));

void main() {
  group('MAISON — états', () {
    testWidgets('maison vide : message, aide, CTA ; aucun faux contenu', (tester) async {
      final home = FakeHomeRepository();
      await pumpApp(tester, home: home);
      await openHouse(tester);
      expect(find.text('Votre maison'), findsOneWidget);
      expect(find.text("Ajoutez vos équipements pour que Nalvium se souvienne de ce qu'il y a chez vous."), findsOneWidget);
      expect(find.text('Vos diagnostics pourront ensuite être rattachés automatiquement à vos équipements.'), findsOneWidget);
      expect(find.text('Ajouter un équipement'), findsOneWidget);
      expect(find.textContaining('Lave'), findsNothing);
      expect(home.calls, ['home']); // un seul appel groupé pour ouvrir la Maison
    });

    testWidgets('ouvrir Maison affiche la bannière mais ne compte aucun diagnostic', (tester) async {
      final ads = FakeAdsService();
      await pumpApp(tester, home: FakeHomeRepository(), ads: ads);
      await openHouse(tester);
      expect(ads.newDiagnostics, 0);
      expect(find.byKey(const Key('ad-slot')).hitTestable(), findsOneWidget); // bannière discrète : ce n'est pas un diagnostic
    });

    testWidgets('maison remplie : groupée par pièce, compteurs honnêtes, sans marque', (tester) async {
      final home = FakeHomeRepository(items: [
        equipment(id: 'a', brand: 'Bosch', diagnostics: 2),
        equipment(id: 'b', type: 'oven', name: 'Four', brand: 'Samsung'),
        equipment(id: 'c', type: 'water_heater', name: 'Chauffe-eau', room: 'bathroom', brand: 'Atlantic', diagnostics: 1),
        equipment(id: 'd', type: 'light', name: 'Luminaire', room: null),
      ]);
      await pumpApp(tester, home: home);
      await openHouse(tester);
      expect(find.text('Cuisine'), findsOneWidget);
      expect(find.text('Salle de bain'), findsOneWidget);
      expect(find.text('Sans pièce'), findsOneWidget);
      expect(find.text('2 diagnostics'), findsOneWidget);
      expect(find.text('1 diagnostic'), findsOneWidget);
      expect(find.text('Aucun problème'), findsNWidgets(2));
      expect(find.text('Bosch'), findsOneWidget);
      expect(find.text('Marque non renseignée'), findsOneWidget);
      expect(find.text('Ajouter un équipement'), findsOneWidget);
    });

    testWidgets('backend indisponible : erreur honnête + réessayer', (tester) async {
      final home = FakeHomeRepository()..homeError = const ApiNetworkException();
      await pumpApp(tester, home: home);
      await openHouse(tester);
      expect(byKey('error-title'), findsOneWidget);
      home.homeError = null;
      await tester.tap(byKey('retry'));
      await tester.pumpAndSettle();
      expect(find.text('Ajouter un équipement'), findsOneWidget);
    });
  });

  group('AJOUT MANUEL', () {
    testWidgets('« Lave-vaisselle — Cuisine » sans marque, modèle ni photo', (tester) async {
      final home = FakeHomeRepository();
      await pumpApp(tester, home: home);
      await openHouse(tester);
      await tester.tap(byKey('house-add'));
      await tester.pumpAndSettle();
      expect(find.text('Quel équipement ?'), findsOneWidget);
      await tester.tap(byKey('kind-dishwasher'));
      await tester.pumpAndSettle();
      expect(find.text('Où se trouve-t-il ?'), findsOneWidget);
      await tester.tap(byKey('room-kitchen'));
      await tester.pumpAndSettle();
      expect(find.text('Quelques précisions'), findsOneWidget);
      expect(find.text('Lave-vaisselle — Cuisine'), findsOneWidget);
      await tester.tap(byKey('add-save'));
      await tester.pumpAndSettle();

      expect(home.created.single.equipmentType, 'dishwasher');
      expect(home.created.single.roomType, 'kitchen');
      expect(home.created.single.toJson().containsKey('brand'), isFalse); // facultatif : rien d'inventé
      expect(home.created.single.toJson().containsKey('primary_media_id'), isFalse);
      expect(byKey('equipment-new1'), findsOneWidget); // retour à la maison, équipement visible
    });

    testWidgets('marque et modèle facultatifs mais enregistrés quand saisis', (tester) async {
      final home = FakeHomeRepository();
      await pumpApp(tester, home: home);
      await openHouse(tester);
      await tester.tap(byKey('house-add'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('kind-oven'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('room-skip'));
      await tester.pumpAndSettle();
      await tester.enterText(byKey('field-brand'), 'Samsung');
      await tester.enterText(byKey('field-model'), 'NV7B');
      await tester.tap(byKey('add-save'));
      await tester.pumpAndSettle();
      final d = home.created.single;
      expect((d.equipmentType, d.roomType, d.brand, d.model), ('oven', null, 'Samsung', 'NV7B'));
      expect(find.text('Sans pièce'), findsOneWidget);
    });

    testWidgets('recherche, aucun résultat → « Autre » avec nom obligatoire', (tester) async {
      final home = FakeHomeRepository();
      await pumpApp(tester, home: home);
      await openHouse(tester);
      await tester.tap(byKey('house-add'));
      await tester.pumpAndSettle();
      await tester.enterText(byKey('add-search'), 'lave');
      await tester.pumpAndSettle();
      expect(byKey('kind-dishwasher'), findsOneWidget);
      expect(byKey('kind-washing_machine'), findsOneWidget);
      expect(byKey('kind-oven'), findsNothing);
      await tester.enterText(byKey('add-search'), 'zzzz');
      await tester.pumpAndSettle();
      expect(byKey('add-search-empty'), findsOneWidget);
      await tester.tap(byKey('kind-other'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('room-skip'));
      await tester.pumpAndSettle();
      // « Autre » exige un nom pour ne pas enregistrer un équipement anonyme
      expect(tester.widget<PrimaryButton>(find.byKey(const Key('add-save'))).onPressed, isNull);
      await tester.enterText(byKey('field-name'), 'Barbecue');
      await tester.pumpAndSettle();
      await tester.tap(byKey('add-save'));
      await tester.pumpAndSettle();
      expect(home.created.single.displayName, 'Barbecue');
    });

    testWidgets('échec d’enregistrement : la saisie est conservée', (tester) async {
      final home = FakeHomeRepository()..createError = const ApiNetworkException();
      await pumpApp(tester, home: home);
      await openHouse(tester);
      await tester.tap(byKey('house-add'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('kind-dishwasher'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('room-kitchen'));
      await tester.pumpAndSettle();
      await tester.enterText(byKey('field-brand'), 'Bosch');
      await tester.tap(byKey('add-save'));
      await tester.pumpAndSettle();
      expect(byKey('add-error'), findsOneWidget);
      expect(find.text('Bosch'), findsOneWidget); // champ conservé
      home.createError = null;
      await tester.tap(byKey('add-save'));
      await tester.pumpAndSettle();
      expect(home.created.single.brand, 'Bosch');
    });

    testWidgets('photo facultative : ajout puis échec d’upload sans perte', (tester) async {
      final home = FakeHomeRepository();
      await pumpApp(tester, home: home, captures: [CapturedPhoto(tempPhotoPath('eq1'))]);
      await openHouse(tester);
      await tester.tap(byKey('house-add'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('kind-fridge'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('room-kitchen'));
      await tester.pumpAndSettle();
      home.uploadError = const ApiTimeoutException();
      await tester.tap(byKey('add-photo-button'));
      await tester.pumpAndSettle();
      expect(byKey('add-error'), findsOneWidget);
      expect(byKey('add-photo'), findsNothing);
      home.uploadError = null;
      await tester.tap(byKey('add-photo-button'));
      await tester.pumpAndSettle();
      expect(byKey('add-photo'), findsOneWidget);
      await tester.tap(byKey('add-save'));
      await tester.pumpAndSettle();
      expect(home.created.single.photoMediaId, 'photo2');
    });

    testWidgets('retour arrière dans le flux', (tester) async {
      await pumpApp(tester, home: FakeHomeRepository());
      await openHouse(tester);
      await tester.tap(byKey('house-add'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('kind-oven'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('add-back'));
      await tester.pumpAndSettle();
      expect(find.text('Quel équipement ?'), findsOneWidget);
    });
  });

  group('IDENTIFICATION PAR PHOTO', () {
    Future<void> toIdentify(WidgetTester tester) async {
      await openHouse(tester);
      await tester.tap(byKey('house-add'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('add-identify'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('identify-take'));
      await tester.pumpAndSettle();
    }

    testWidgets('formulation prudente + confirmation → étape pièce préremplie', (tester) async {
      final home = FakeHomeRepository();
      final ads = FakeAdsService();
      await pumpApp(tester, home: home, ads: ads, captures: [CapturedPhoto(tempPhotoPath('id1'))]);
      await toIdentify(tester);
      expect(find.text('Cela ressemble à un lave-vaisselle Bosch.'), findsOneWidget);
      expect(byKey('identify-not-sure'), findsOneWidget);
      expect(byKey('identify-model'), findsNothing); // aucun modèle inventé
      await tester.tap(byKey('identify-confirm'));
      await tester.pumpAndSettle();
      expect(find.text('Où se trouve-t-il ?'), findsOneWidget);
      await tester.tap(byKey('room-kitchen'));
      await tester.pumpAndSettle();
      expect(find.text('Bosch'), findsOneWidget); // marque préremplie
      expect(byKey('add-photo'), findsOneWidget); // la photo devient la photo principale
      await tester.tap(byKey('add-save'));
      await tester.pumpAndSettle();
      expect(home.created.single.equipmentType, 'dishwasher');
      expect(home.created.single.photoMediaId, 'photo1');
      expect(home.calls.where((c) => c.startsWith('identify')), ['identify:photo1']);
      expect(ads.newDiagnostics, 0); // ce n'est pas un diagnostic
    });

    testWidgets('« Corriger » ouvre le choix du type avec la proposition présélectionnée', (tester) async {
      final home = FakeHomeRepository();
      await pumpApp(tester, home: home, captures: [CapturedPhoto(tempPhotoPath('id2'))]);
      await toIdentify(tester);
      await tester.tap(byKey('identify-correct'));
      await tester.pumpAndSettle();
      expect(find.text('Quel équipement ?'), findsOneWidget);
      await tester.tap(byKey('kind-washing_machine'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('room-laundry'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('add-save'));
      await tester.pumpAndSettle();
      expect(home.created.single.equipmentType, 'washing_machine');
    });

    testWidgets('modèle lisible affiché ; type inconnu → on choisit soi-même, photo conservée', (tester) async {
      final home = FakeHomeRepository()
        ..identification = const EquipmentIdentification(equipmentType: 'oven', brand: 'Samsung', model: 'NV7B', confidence: 0.7);
      await pumpApp(tester, home: home, captures: [CapturedPhoto(tempPhotoPath('id3'))]);
      await toIdentify(tester);
      expect(find.text('Modèle / référence : NV7B'), findsOneWidget);
      await tester.tap(byKey('identify-close'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('house-add'));
      await tester.pumpAndSettle();

      home.identification = const EquipmentIdentification(equipmentType: 'unknown', confidence: 0.1);
      await tester.tap(byKey('add-identify'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('identify-take'));
      await tester.pumpAndSettle();
      expect(byKey('identify-unknown'), findsOneWidget);
      expect(find.textContaining('Cela ressemble'), findsNothing);
      await tester.tap(byKey('identify-choose'));
      await tester.pumpAndSettle();
      expect(find.text('Quel équipement ?'), findsOneWidget);
      expect(byKey('add-identify'), findsNothing); // la photo est déjà là
    });

    testWidgets('IA indisponible : on peut continuer sans identification', (tester) async {
      final home = FakeHomeRepository()..identifyError = const ApiHttpException(503, 'identification_unavailable');
      await pumpApp(tester, home: home, captures: [CapturedPhoto(tempPhotoPath('id4'))]);
      await toIdentify(tester);
      expect(byKey('identify-failed'), findsOneWidget);
      // réessayer ne renvoie PAS la photo une seconde fois
      home.identifyError = null;
      await tester.tap(byKey('retry'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Cela ressemble'), findsOneWidget);
      expect(home.calls.where((c) => c == 'upload').length, 1);
    });

    testWidgets('upload impossible : erreur honnête, réessayer, sinon choisir soi-même', (tester) async {
      final home = FakeHomeRepository()..uploadError = const ApiNetworkException();
      await pumpApp(tester, home: home, captures: [CapturedPhoto(tempPhotoPath('id5'))]);
      await toIdentify(tester);
      expect(byKey('error-title'), findsOneWidget);
      expect(byKey('identify-manual'), findsOneWidget);
    });

    testWidgets('fermer après envoi de la photo : la photo temporaire est supprimée tout de suite', (tester) async {
      final home = FakeHomeRepository();
      await pumpApp(tester, home: home, captures: [CapturedPhoto(tempPhotoPath('orph1'))]);
      await toIdentify(tester);
      await tester.tap(byKey('identify-close'));
      await tester.pumpAndSettle();
      expect(home.discarded, ['photo1']);
    });

    testWidgets('confirmer puis revenir en arrière ne supprime rien ; fermer le flux supprime la photo temporaire', (tester) async {
      final home = FakeHomeRepository();
      await pumpApp(tester, home: home, captures: [CapturedPhoto(tempPhotoPath('orph2'))]);
      await toIdentify(tester);
      await tester.tap(byKey('identify-confirm'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('add-back')); // simple retour d'étape : rien n'est supprimé
      await tester.pumpAndSettle();
      expect(home.discarded, isEmpty);
      await tester.tap(byKey('add-back')); // fermeture explicite du flux : abandon
      await tester.pumpAndSettle();
      expect(home.discarded, ['photo1']);
    });

    testWidgets('annuler la caméra reste sur l’introduction', (tester) async {
      await pumpApp(tester, home: FakeHomeRepository(), captures: const [null]);
      await openHouse(tester);
      await tester.tap(byKey('house-add'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('add-identify'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('identify-take'));
      await tester.pumpAndSettle();
      expect(byKey('identify-take'), findsOneWidget);
    });
  });

  group('FICHE ÉQUIPEMENT', () {
    EquipmentDiagnostic diag(String id, String title, String status, DateTime d) =>
        EquipmentDiagnostic(id: id, status: status, title: title, updatedAt: d);

    testWidgets('infos, problèmes traités avec statut, sans marque', (tester) async {
      final home = FakeHomeRepository(
        items: [equipment(id: 'a', brand: 'Bosch', model: 'SMS46', diagnostics: 2), equipment(id: 'b', type: 'oven', name: 'Four')],
        diagnostics: {
          'a': [
            diag('s1', 'Ne vidange plus', 'resolved', DateTime(2020, 3, 12)),
            diag('s2', 'Fuite sous l’appareil', 'referred', DateTime(2020, 2, 18)),
          ],
        },
      );
      await pumpApp(tester, home: home);
      await openHouse(tester);
      await tester.tap(byKey('equipment-a'));
      await tester.pumpAndSettle();
      expect(find.text('Lave-vaisselle'), findsOneWidget);
      expect(find.text('Bosch'), findsOneWidget);
      expect(find.text('Référence : SMS46'), findsOneWidget);
      expect(find.text('Cuisine'), findsOneWidget);
      expect(find.text('Problèmes traités'), findsOneWidget);
      expect(find.text('Ne vidange plus'), findsOneWidget);
      expect(find.text('Résolu'), findsOneWidget);
      expect(find.text('Professionnel recommandé'), findsOneWidget);
      expect(find.text('12 mars 2020'), findsOneWidget);
      expect(byKey('equipment-diagnose'), findsOneWidget);

      await tester.tap(byKey('equipment-back'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('equipment-b'));
      await tester.pumpAndSettle();
      expect(byKey('equipment-no-brand'), findsOneWidget);
      expect(find.text('Aucun problème enregistré pour cet équipement.'), findsOneWidget);
    });

    testWidgets('équipement supprimé ailleurs : message clair et retour', (tester) async {
      await pumpApp(tester, home: FakeHomeRepository(), location: '/equipment/disparu');
      expect(byKey('equipment-gone'), findsOneWidget);
      expect(find.text("Cet équipement n'existe plus."), findsOneWidget);
      expect(byKey('error-title'), findsNothing);
    });

    testWidgets('modification : nom, type, pièce, marque, modèle', (tester) async {
      final home = FakeHomeRepository(items: [equipment(id: 'a', brand: 'Bosch')]);
      await pumpApp(tester, home: home);
      await openHouse(tester);
      await tester.tap(byKey('equipment-a'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('equipment-edit'));
      await tester.pumpAndSettle();
      await tester.enterText(byKey('edit-name'), 'Lave-vaisselle du fond');
      await tester.enterText(byKey('edit-brand'), '');
      await tester.enterText(byKey('edit-model'), 'SMS46');
      await tester.tap(byKey('edit-room'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('pick-laundry'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('edit-save'));
      await tester.pumpAndSettle();
      final u = home.updates.single;
      expect(u['display_name'], 'Lave-vaisselle du fond');
      expect(u['room_type'], 'laundry');
      expect(u['brand'], '');
      expect(u['model'], 'SMS46');
      expect(find.text('Lave-vaisselle du fond'), findsOneWidget);
      expect(find.text('Buanderie'), findsOneWidget);
    });

    testWidgets('modification échouée : saisie conservée', (tester) async {
      final home = FakeHomeRepository(items: [equipment(id: 'a')])..updateError = const ApiNetworkException();
      await pumpApp(tester, home: home);
      await openHouse(tester);
      await tester.tap(byKey('equipment-a'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('equipment-edit'));
      await tester.pumpAndSettle();
      await tester.enterText(byKey('edit-brand'), 'Miele');
      await tester.tap(byKey('edit-save'));
      await tester.pumpAndSettle();
      expect(byKey('edit-error'), findsOneWidget);
      expect(find.text('Miele'), findsOneWidget);
    });

    testWidgets('suppression : explique que les diagnostics sont conservés, demande confirmation', (tester) async {
      final home = FakeHomeRepository(items: [equipment(id: 'a')]);
      await pumpApp(tester, home: home);
      await openHouse(tester);
      await tester.tap(byKey('equipment-a'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('equipment-delete'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ne seront pas supprimés'), findsOneWidget);
      await tester.tap(byKey('delete-cancel'));
      await tester.pumpAndSettle();
      expect(home.calls.where((c) => c.startsWith('delete')), isEmpty);
      await tester.tap(byKey('equipment-delete'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('delete-confirm'));
      await tester.pumpAndSettle();
      expect(home.calls, contains('delete:a'));
      expect(find.text('Ajoutez vos équipements pour que Nalvium se souvienne de ce qu\'il y a chez vous.'), findsOneWidget);
    });

    testWidgets('suppression en échec : message, l’équipement reste', (tester) async {
      final home = FakeHomeRepository(items: [equipment(id: 'a')])..deleteError = const ApiNetworkException();
      await pumpApp(tester, home: home);
      await openHouse(tester);
      await tester.tap(byKey('equipment-a'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('equipment-delete'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('delete-confirm'));
      await tester.pumpAndSettle();
      expect(find.text("L'équipement n'a pas pu être supprimé. Réessayez."), findsOneWidget);
      expect(byKey('equipment-diagnose'), findsOneWidget);
    });
  });

  group('DIAGNOSTIC DEPUIS UN ÉQUIPEMENT', () {
    testWidgets('description → session liée à l’équipement dès sa création, publicité avant la session', (tester) async {
      final home = FakeHomeRepository(items: [equipment(id: 'a', brand: 'Bosch')]);
      final repo = FakeSessionsRepository(turns: [
        sessionState(action: NextActionType.askQuestion, message: 'Entendez-vous la pompe ?', choices: const ['Oui', 'Non']),
      ]);
      final ads = FakeAdsService();
      await pumpApp(tester, home: home, repo: repo, ads: ads);
      await openHouse(tester);
      await tester.tap(byKey('equipment-a'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('equipment-diagnose'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('diagnose-describe'));
      await tester.pumpAndSettle();
      await tester.enterText(byKey('describe-field'), 'Elle ne vidange plus');
      await tester.pumpAndSettle();
      await tester.tap(byKey('describe-continue'));
      await tester.pumpAndSettle();

      expect(repo.createdWithEquipment, ['a']);
      expect(ads.newDiagnostics, 1); // c'est bien un NOUVEAU diagnostic (publicité éventuelle AVANT la session)
      expect(find.text('Entendez-vous la pompe ?'), findsOneWidget);
    });

    testWidgets('photo → même liaison', (tester) async {
      final home = FakeHomeRepository(items: [equipment(id: 'a')]);
      final repo = FakeSessionsRepository(turns: [sessionState(action: NextActionType.askQuestion, message: 'Q ?', choices: const ['Oui'])]);
      await pumpApp(tester, home: home, repo: repo, captures: [CapturedPhoto(tempPhotoPath('diag1'))]);
      await openHouse(tester);
      await tester.tap(byKey('equipment-a'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('equipment-diagnose'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('diagnose-photo'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('use-photo'));
      await tester.pumpAndSettle();
      expect(repo.createdWithEquipment, ['a']);
    });

    testWidgets('un diagnostic libre depuis l’accueil n’est lié à aucun équipement', (tester) async {
      final repo = FakeSessionsRepository(turns: [sessionState(action: NextActionType.askQuestion, message: 'Q ?', choices: const ['Oui'])]);
      await pumpApp(tester, repo: repo);
      await tester.tap(byKey('describe-problem'));
      await tester.pumpAndSettle();
      await tester.enterText(byKey('describe-field'), 'fuite');
      await tester.pumpAndSettle();
      await tester.tap(byKey('describe-continue'));
      await tester.pumpAndSettle();
      expect(repo.createdWithEquipment, [null]);
    });
  });

  group('AJOUTER UN DIAGNOSTIC À LA MAISON', () {
    Map<String, dynamic> linked() => {
      'id': 'e1', 'equipment_type': 'dishwasher', 'display_name': 'Lave-vaisselle', 'brand': 'Bosch', 'model': null,
      'room_type': 'kitchen', 'room_name': 'Cuisine',
    };

    testWidgets('récapitulatif : proposition discrète, jamais de liaison silencieuse', (tester) async {
      final home = FakeHomeRepository(items: [equipment(id: 'e1', brand: 'Bosch')])
        ..suggested = EquipmentSuggestions(detectedType: 'dishwasher', matches: [equipment(id: 'e1', brand: 'Bosch')]);
      final repo = FakeSessionsRepository(
        sessions: [summary(id: 'r1', title: 'Lave-vaisselle qui ne vidange plus', status: 'resolved', state: 'RESOLVED')],
        stored: sessionState(id: 'r1', action: NextActionType.resolved, status: 'resolved', message: 'Réglé.'),
      );
      await pumpApp(tester, home: home, repo: repo);
      await tester.tap(byKey('open-history'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('history-r1'));
      await tester.pumpAndSettle();
      expect(byKey('summary-add-house'), findsOneWidget);
      expect(home.links, isEmpty); // rien n'a été lié

      await tester.tap(byKey('summary-add-house'));
      await tester.pumpAndSettle();
      expect(find.text('Est-ce votre lave-vaisselle Bosch (Cuisine) ?'), findsOneWidget);
      expect(home.links, isEmpty); // toujours rien : l'utilisateur doit confirmer
      await tester.tap(byKey('link-yes'));
      await tester.pumpAndSettle();
      expect(home.links, [('r1', 'e1')]);
    });

    testWidgets('refuser la suggestion puis choisir un autre équipement existant', (tester) async {
      final home = FakeHomeRepository(items: [equipment(id: 'e1'), equipment(id: 'e2', type: 'oven', name: 'Four')])
        ..suggested = EquipmentSuggestions(detectedType: 'dishwasher', matches: [equipment(id: 'e1')]);
      final repo = FakeSessionsRepository(
        sessions: [summary(id: 'r1', status: 'resolved', state: 'RESOLVED')],
        stored: sessionState(id: 'r1', action: NextActionType.resolved, status: 'resolved', message: 'Réglé.'),
      );
      await pumpApp(tester, home: home, repo: repo);
      await tester.tap(byKey('open-history'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('history-r1'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('summary-add-house'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('link-no'));
      await tester.pumpAndSettle();
      expect(byKey('link-ask'), findsNothing);
      await tester.tap(byKey('link-pick-e2'));
      await tester.pumpAndSettle();
      expect(home.links, [('r1', 'e2')]);
    });

    testWidgets('créer un nouvel équipement depuis un diagnostic (type détecté proposé)', (tester) async {
      final home = FakeHomeRepository()..suggested = const EquipmentSuggestions(detectedType: 'dishwasher');
      final repo = FakeSessionsRepository(
        sessions: [summary(id: 'r1', status: 'resolved', state: 'RESOLVED')],
        stored: sessionState(id: 'r1', action: NextActionType.resolved, status: 'resolved', message: 'Réglé.'),
      );
      await pumpApp(tester, home: home, repo: repo);
      await tester.tap(byKey('open-history'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('history-r1'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('summary-add-house'));
      await tester.pumpAndSettle();
      expect(byKey('link-nothing'), findsOneWidget);
      await tester.tap(byKey('link-new'));
      await tester.pumpAndSettle();
      expect(find.text('Où se trouve-t-il ?'), findsOneWidget); // type détecté déjà proposé
      await tester.tap(byKey('room-kitchen'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('add-save'));
      await tester.pumpAndSettle();
      expect(home.created.single.equipmentType, 'dishwasher');
      expect(home.links, [('r1', 'new1')]);
    });

    testWidgets('échec du rattachement : message, aucune perte', (tester) async {
      final home = FakeHomeRepository(items: [equipment(id: 'e1')])..linkError = const ApiNetworkException();
      final repo = FakeSessionsRepository(
        sessions: [summary(id: 'r1', status: 'resolved', state: 'RESOLVED')],
        stored: sessionState(id: 'r1', action: NextActionType.resolved, status: 'resolved', message: 'Réglé.'),
      );
      await pumpApp(tester, home: home, repo: repo);
      await tester.tap(byKey('open-history'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('history-r1'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('summary-add-house'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('link-pick-e1'));
      await tester.pumpAndSettle();
      expect(byKey('link-error'), findsOneWidget);
      expect(byKey('link-pick-e1'), findsOneWidget);
    });

    testWidgets('récapitulatif d’une session déjà liée : équipement affiché, pas de proposition', (tester) async {
      final repo = FakeSessionsRepository(
        sessions: [summary(id: 'r1', status: 'resolved', state: 'RESOLVED')],
        stored: sessionState(id: 'r1', action: NextActionType.resolved, status: 'resolved', message: 'Réglé.', equipment: linked()),
      );
      await pumpApp(tester, home: FakeHomeRepository(items: [equipment(id: 'e1', brand: 'Bosch')]), repo: repo);
      await tester.tap(byKey('open-history'));
      await tester.pumpAndSettle();
      await tester.tap(byKey('history-r1'));
      await tester.pumpAndSettle();
      expect(byKey('summary-add-house'), findsNothing);
      expect(find.text('Lave-vaisselle · Bosch · Cuisine'), findsOneWidget);
    });

    testWidgets('après RESOLVED : « Enregistrer cet équipement » est secondaire et optionnel', (tester) async {
      final repo = FakeSessionsRepository(turns: [
        sessionState(action: NextActionType.resolved, status: 'resolved', message: 'Réglé.'),
      ]);
      await pumpApp(tester, home: FakeHomeRepository(), repo: repo);
      await tester.tap(byKey('describe-problem'));
      await tester.pumpAndSettle();
      await tester.enterText(byKey('describe-field'), 'ça fuit');
      await tester.pumpAndSettle();
      await tester.tap(byKey('describe-continue'));
      await tester.pumpAndSettle();
      expect(byKey('resolved-finish'), findsOneWidget); // la résolution n'est jamais bloquée
      expect(byKey('resolved-save-equipment'), findsOneWidget);
      await tester.tap(byKey('resolved-finish'));
      await tester.pumpAndSettle();
      expect(find.text('Un problème à la maison ?'), findsOneWidget);
    });

    testWidgets('RESOLVED d’une session déjà liée : aucune proposition', (tester) async {
      final repo = FakeSessionsRepository(turns: [
        sessionState(action: NextActionType.resolved, status: 'resolved', message: 'Réglé.', equipment: linked()),
      ]);
      await pumpApp(tester, home: FakeHomeRepository(), repo: repo);
      await tester.tap(byKey('describe-problem'));
      await tester.pumpAndSettle();
      await tester.enterText(byKey('describe-field'), 'ça fuit');
      await tester.pumpAndSettle();
      await tester.tap(byKey('describe-continue'));
      await tester.pumpAndSettle();
      expect(byKey('resolved-save-equipment'), findsNothing);
    });
  });
}
