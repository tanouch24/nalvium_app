import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/core/network/api_exceptions.dart';
import 'package:nalvium/domain/diagnosis.dart';
import 'package:nalvium/domain/service_request.dart';
import 'package:nalvium/domain/session.dart';

import 'helpers/fake_requests.dart';
import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

Finder k(String key) => find.byKey(Key(key));

/// Appels qui ÉCRIVENT (la liste et la relecture ne comptent pas).
List<String> writes(FakeServiceRequestsRepository r) => [for (final c in r.calls) if (!c.startsWith('get') && c != 'list' && c != 'area') c];
Finder get ad => find.byKey(const Key('ad-slot')).hitTestable();

Future<void> see(WidgetTester t, String key) async {
  if (k(key).evaluate().isEmpty) {
    await t.scrollUntilVisible(k(key), 300, scrollable: find.byType(Scrollable).first);
  }
  await t.ensureVisible(k(key));
  await t.pumpAndSettle();
}

Future<void> tapK(WidgetTester t, String key) async {
  await see(t, key);
  await t.tap(k(key));
  await t.pumpAndSettle();
}

Future<void> typeK(WidgetTester t, String key, String text) async {
  await see(t, key);
  await t.enterText(k(key), text);
  await t.pumpAndSettle();
}

/// Remplit le formulaire de coordonnées avec des données de TEST non personnelles.
Future<void> fillContact(WidgetTester t, {String phone = '06 12 34 56 78', String postal = '69003'}) async {
  await typeK(t, 'help-first', 'Camille');
  await typeK(t, 'help-phone', phone);
  await typeK(t, 'help-city', 'Lyon');
  await typeK(t, 'help-postal', postal);
}

const _ctx = {
  'source': 'diagnostic', 'diagnostic_status': 'active',
  'equipment': {'type': 'dishwasher', 'label': 'Lave-vaisselle', 'name': 'Lave-vaisselle', 'brand': 'Bosch', 'model': 'SMV4HVX31E', 'room': 'Cuisine'},
  'observations': ['Eau au fond de la cuve'],
  'hypotheses': [{'label': 'Filtre obstrué', 'note': 'hypothèse'}],
  'actions_tried': [{'instruction': 'Retirez le panier inférieur.', 'result': 'fait'}],
  'manual': {'consulted': true, 'manufacturer': 'Bosch', 'model': 'SMV4HVX31E', 'pages': [43, 51]},
};

Future<FakeServiceRequestsRepository> startFromDiagnostic(WidgetTester t, {SessionState? session, FakeServiceRequestsRepository? requests, FakeAdsService? ads, Size? size, double scale = 1.0}) async {
  final reqs = requests ?? FakeServiceRequestsRepository(draftContext: Map<String, dynamic>.of(_ctx));
  final s = session ?? sessionState(action: NextActionType.askQuestion, message: 'Q ?', choices: const ['Oui'], media: const [
    {'id': 'm1', 'media_type': 'photo'}, {'id': 'm2', 'media_type': 'photo'}, {'id': 'v1', 'media_type': 'video'},
  ]);
  await pumpApp(t, repo: FakeSessionsRepository(stored: s), requests: reqs, ads: ads, location: '/session/s1', size: size ?? const Size(1080, 3600), textScale: scale);
  await tapK(t, 'ask-for-help');
  return reqs;
}

void main() {
  group('DÉPANNAGE', () {
    testWidgets('vide : titre, texte, CTA principal, aucune fausse demande, bannière autorisée', (tester) async {
      await pumpApp(tester, location: '/repair');
      expect(find.text("Besoin d'un coup de main ?"), findsOneWidget);
      expect(find.textContaining('pour que vous n\'ayez pas à tout réexpliquer'), findsOneWidget);
      expect(find.text('Demander une intervention'), findsOneWidget);
      expect(k('repair-empty'), findsOneWidget);
      expect(ad, findsOneWidget);
    });

    testWidgets('liste : seulement les vraies demandes (problème, équipement, statut, ville, date)', (tester) async {
      final reqs = FakeServiceRequestsRepository(items: [
        request(id: 'a', summary: 'Lave-vaisselle qui ne vidange plus', equipmentLabel: 'Lave-vaisselle Bosch'),
        request(id: 'b', summary: 'Prise qui chauffe', status: 'CANCELLED'),
      ]);
      await pumpApp(tester, requests: reqs, location: '/repair');
      expect(find.text('Lave-vaisselle qui ne vidange plus'), findsOneWidget);
      expect(find.text('Lave-vaisselle Bosch'), findsOneWidget);
      expect(find.text('Demande envoyée'), findsOneWidget);
      expect(find.text('Annulée'), findsOneWidget);
      expect(find.textContaining('Lyon'), findsNWidgets(2));
      expect(find.textContaining('professionnel disponible'), findsNothing);
      expect(ad, findsOneWidget);
    });

    testWidgets('erreur de chargement honnête', (tester) async {
      final reqs = FakeServiceRequestsRepository()..listError = const ApiNetworkException();
      await pumpApp(tester, requests: reqs, location: '/repair');
      expect(k('repair-load-fail'), findsOneWidget);
      reqs.listError = null;
      await tester.tap(k('retry'));
      await tester.pumpAndSettle();
      expect(k('repair-empty'), findsOneWidget);
    });
  });

  group('DEMANDE SANS DIAGNOSTIC', () {
    testWidgets('parcours rapide : aucun appel IA, aucune pub, aucun compteur ; envoi complet', (tester) async {
      final ads = FakeAdsService();
      final reqs = FakeServiceRequestsRepository();
      await pumpApp(tester, requests: reqs, ads: ads, location: '/repair');
      await tapK(tester, 'repair-ask');
      expect(k('help-intro'), findsOneWidget);
      expect(ad, findsNothing); // formulaire sensible : pas de bannière
      await typeK(tester, 'help-summary', 'Mon volet roulant est bloqué');
      await tapK(tester, 'help-cat-handyman');
      await fillContact(tester);
      await tapK(tester, 'help-when-today');
      await tapK(tester, 'help-consent');
      await tapK(tester, 'help-send');
      expect(writes(reqs), ['create', 'update', 'media', 'submit']);
      final u = reqs.updates.single;
      expect(u['problem_summary'], 'Mon volet roulant est bloqué');
      expect(u['category'], 'handyman');
      expect(u['phone'], '06 12 34 56 78');
      expect(u['availability_type'], 'today');
      expect(reqs.mediaSelections.single, isEmpty);
      expect(k('help-done-title'), findsOneWidget);
      expect(find.text('Votre demande est envoyée'), findsOneWidget);
      expect(ads.newDiagnostics, 0); // demander de l'aide n'est pas un diagnostic
      expect(ad, findsNothing);
    });
  });

  group('DEMANDE DEPUIS UN DIAGNOSTIC', () {
    testWidgets('bouton secondaire discret sur ASK/PHOTO/INSTRUCTION/VERIFICATION', (tester) async {
      for (final a in [NextActionType.askQuestion, NextActionType.requestPhoto, NextActionType.instruction, NextActionType.verification]) {
        await pumpApp(tester, repo: FakeSessionsRepository(stored: sessionState(action: a, message: 'Texte.', choices: const ['Oui'])), location: '/session/s1');
        expect(k('ask-for-help'), findsOneWidget, reason: a.name);
      }
    });

    testWidgets('absent sur RESOLVED (écran propre)', (tester) async {
      await pumpApp(tester, repo: FakeSessionsRepository(stored: sessionState(action: NextActionType.resolved, status: 'resolved', message: 'Réglé.')), location: '/session/s1');
      expect(k('ask-for-help'), findsNothing);
    });

    testWidgets('contexte du diagnostic déjà prêt : problème, équipement, déjà essayé, notice (hypothèse présentée comme telle)', (tester) async {
      final reqs = await startFromDiagnostic(tester);
      expect(reqs.lastSessionId, 's1');
      expect(tester.widget<TextField>(k('help-summary')).controller!.text, 'Lave-vaisselle qui ne vidange plus');
      await see(tester, 'help-equipment');
      expect(find.textContaining('Bosch'), findsWidgets);
      expect(find.textContaining('Retirez le panier inférieur. (fait)'), findsOneWidget);
      expect(find.text('Eau au fond de la cuve'), findsOneWidget);
      expect(find.textContaining('Hypothèse de Nalvium, non confirmée par un professionnel : Filtre obstrué'), findsOneWidget);
      expect(find.textContaining('Notice constructeur consultée · pages 43, 51'), findsOneWidget);
      expect(find.textContaining('PDF'), findsNothing);
    });

    testWidgets('titre « Ce que Nalvium a constaté » quand la section regroupe observations/hypothèses/actions', (tester) async {
      await startFromDiagnostic(tester);
      expect(find.text('Ce que Nalvium a constaté'), findsOneWidget);
      expect(find.text('Déjà essayé'), findsNothing);
    });

    testWidgets('seulement des actions : « Déjà essayé »', (tester) async {
      final reqs = FakeServiceRequestsRepository(draftContext: {
        'source': 'diagnostic', 'actions_tried': [{'instruction': 'Fermez le robinet.', 'result': 'fait'}],
      });
      await startFromDiagnostic(tester, requests: reqs);
      expect(find.text('Déjà essayé'), findsOneWidget);
      expect(find.text('Ce que Nalvium a constaté'), findsNothing);
    });

    testWidgets('le diagnostic n’est pas détruit : on peut revenir', (tester) async {
      await startFromDiagnostic(tester);
      await tester.tap(k('help-close'));
      await tester.pumpAndSettle();
      expect(find.text('Q ?'), findsOneWidget);
    });

    testWidgets('aucune bannière pendant le diagnostic ni sur le formulaire', (tester) async {
      await pumpApp(tester, repo: FakeSessionsRepository(stored: sessionState(action: NextActionType.askQuestion, message: 'Q ?', choices: const ['Oui'])), location: '/session/s1');
      expect(ad, findsNothing);
      await tapK(tester, 'ask-for-help');
      expect(ad, findsNothing);
    });
  });

  group('SAFETY STOP', () {
    testWidgets('« Demander de l’aide » est le CTA principal ; la raison du stop est conservée dans la demande', (tester) async {
      final ctx = {..._ctx, 'diagnostic_status': 'stopped', 'safety_stop_reason': "Arrêtez-vous ici. Eau et électricité : coupez l'alimentation."};
      final reqs = FakeServiceRequestsRepository(draftContext: ctx);
      await pumpApp(
        tester,
        repo: FakeSessionsRepository(stored: sessionState(action: NextActionType.safetyStop, status: 'stopped', message: "Arrêtez-vous ici. Eau et électricité : coupez l'alimentation.")),
        requests: reqs,
        location: '/session/s1',
      );
      expect(find.text('Arrêtez-vous ici'), findsOneWidget); // message de sécurité intact
      expect(k('safety-find-pro'), findsOneWidget);
      expect(find.text("Demander de l'aide"), findsOneWidget);
      expect(ad, findsNothing);
      await tester.tap(k('safety-find-pro'));
      await tester.pumpAndSettle();
      await see(tester, 'help-stop-reason');
      expect(find.textContaining("coupez l'alimentation"), findsOneWidget);
      expect(k('help-emergency'), findsOneWidget);
      expect(find.textContaining('18 ou 112'), findsOneWidget);
      expect(find.textContaining('ne remplace'), findsNothing);
      expect(find.textContaining('ne les remplace pas'), findsOneWidget);
    });
  });

  group('FORMULAIRE', () {
    testWidgets('champs vides : erreurs lisibles, rien n’est envoyé, consentement jamais précoché', (tester) async {
      final reqs = await startFromDiagnostic(tester);
      await see(tester, 'help-consent');
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
      await tapK(tester, 'help-send');
      expect(find.text('Ce champ est nécessaire.'), findsWidgets);
      expect(find.text('Vous devez accepter pour envoyer la demande.'), findsOneWidget);
      expect(writes(reqs), ['from-session']); // aucune écriture, aucun envoi
    });

    testWidgets('téléphone et code postal invalides : messages compréhensibles', (tester) async {
      final reqs = await startFromDiagnostic(tester);
      await fillContact(tester, phone: '123', postal: '7501');
      await tapK(tester, 'help-when-asap');
      await tapK(tester, 'help-consent');
      await tapK(tester, 'help-send');
      expect(find.text('Entrez un numéro valide, par exemple 06 12 34 56 78.'), findsOneWidget);
      expect(find.text('Entrez un code postal à 5 chiffres.'), findsOneWidget);
      expect(writes(reqs), ['from-session']);
      await typeK(tester, 'help-phone', '+33 6 12 34 56 78');
      await typeK(tester, 'help-postal', '75011');
      await typeK(tester, 'help-email', 'pas-un-mail');
      await tapK(tester, 'help-send');
      expect(find.text('Cette adresse e-mail semble incorrecte.'), findsOneWidget);
    });

    testWidgets('créneau personnalisé : date + plage obligatoires', (tester) async {
      final reqs = await startFromDiagnostic(tester);
      await fillContact(tester);
      await tapK(tester, 'help-when-custom');
      await tapK(tester, 'help-consent');
      await tapK(tester, 'help-send');
      expect(find.text('Choisissez une date et une plage horaire.'), findsOneWidget);
      await tapK(tester, 'help-pick-date');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tapK(tester, 'help-window-afternoon');
      await tapK(tester, 'help-send');
      expect(reqs.updates.single['preferred_time_window'], 'afternoon');
      expect(reqs.updates.single['preferred_date'], isNotNull);
    });
  });

  group('MÉDIAS ET CONSENTEMENT', () {
    testWidgets('aucun média joint par défaut ; seule la sélection explicite est envoyée', (tester) async {
      final reqs = await startFromDiagnostic(tester);
      await see(tester, 'help-media-privacy');
      expect(find.text('Seuls les éléments sélectionnés seront transmis avec votre demande. Les autres restent privés.'), findsOneWidget);
      await fillContact(tester);
      await tapK(tester, 'help-when-asap');
      await tapK(tester, 'help-media-m2'); // UNE photo sur trois médias
      await tapK(tester, 'help-consent');
      await tapK(tester, 'help-send');
      expect(reqs.mediaSelections.single, ['m2']);
      expect(reqs.mediaSelections.single, isNot(contains('m1')));
      expect(reqs.mediaSelections.single, isNot(contains('v1')));
    });

    testWidgets('sans sélection : aucun média n’est transmis', (tester) async {
      final reqs = await startFromDiagnostic(tester);
      await fillContact(tester);
      await tapK(tester, 'help-when-asap');
      await tapK(tester, 'help-consent');
      await tapK(tester, 'help-send');
      expect(reqs.mediaSelections.single, isEmpty);
    });

    testWidgets('désélectionner retire le média', (tester) async {
      final reqs = await startFromDiagnostic(tester);
      await fillContact(tester);
      await tapK(tester, 'help-when-asap');
      await tapK(tester, 'help-media-m1');
      await tapK(tester, 'help-media-m1');
      await tapK(tester, 'help-consent');
      await tapK(tester, 'help-send');
      expect(reqs.mediaSelections.single, isEmpty);
    });

    testWidgets('échec d’envoi : message honnête, toutes les saisies conservées, réessai possible', (tester) async {
      final reqs = await startFromDiagnostic(tester);
      reqs.submitError = const ApiNetworkException();
      await fillContact(tester);
      await tapK(tester, 'help-when-asap');
      await tapK(tester, 'help-media-m1');
      await tapK(tester, 'help-consent');
      await tapK(tester, 'help-send');
      expect(k('help-send-error'), findsOneWidget);
      expect(tester.widget<TextField>(k('help-first')).controller!.text, 'Camille');
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
      reqs.submitError = null;
      await tapK(tester, 'help-send');
      expect(k('help-done-title'), findsOneWidget);
    });
  });

  group('CONFIRMATION, DÉTAIL, ANNULATION', () {
    testWidgets('confirmation honnête (aucun délai promis) puis détail', (tester) async {
      final reqs = await startFromDiagnostic(tester);
      await fillContact(tester);
      await tapK(tester, 'help-when-tomorrow');
      await tapK(tester, 'help-media-m1');
      await tapK(tester, 'help-consent');
      await tapK(tester, 'help-send');
      expect(find.textContaining('Nous avons enregistré votre demande avec les informations que vous avez choisies de partager'), findsOneWidget);
      expect(find.textContaining('garanti'), findsNothing);
      expect(find.textContaining('arrive'), findsNothing);
      expect(k('help-done-summary'), findsOneWidget);
      await tapK(tester, 'help-done-see');
      expect(find.text('Demande envoyée'), findsOneWidget);
      expect(find.textContaining("pas encore transmis votre demande à un professionnel"), findsOneWidget);
      expect(reqs.items, hasLength(1));
    });

    testWidgets('« Voir ma demande » puis retour → Dépannage / Vos demandes (pas le diagnostic actif)', (tester) async {
      await startFromDiagnostic(tester);
      await fillContact(tester);
      await tapK(tester, 'help-when-asap');
      await tapK(tester, 'help-consent');
      await tapK(tester, 'help-send');
      await tapK(tester, 'help-done-see');
      expect(find.text('Demande envoyée'), findsOneWidget);
      await tester.tap(k('request-back'));
      await tester.pumpAndSettle();
      expect(k('repair-headline'), findsOneWidget);
      expect(find.text('Vos demandes'), findsOneWidget);
      expect(find.text('Q ?'), findsNothing); // le diagnostic n'est pas rouvert
    });

    testWidgets('retour système depuis la confirmation → Dépannage', (tester) async {
      await startFromDiagnostic(tester);
      await fillContact(tester);
      await tapK(tester, 'help-when-asap');
      await tapK(tester, 'help-consent');
      await tapK(tester, 'help-send');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(k('repair-headline'), findsOneWidget);
      expect(find.text('Q ?'), findsNothing);
    });

    testWidgets('détail : informations partagées, annulation avec confirmation', (tester) async {
      final reqs = FakeServiceRequestsRepository(items: [request(id: 'a', media: const ['m1'])]);
      await pumpApp(tester, requests: reqs, location: '/requests/a');
      expect(find.text('Fuite sous mon évier'), findsOneWidget);
      expect(find.textContaining('Camille'), findsOneWidget);
      expect(find.textContaining('69003'), findsOneWidget);
      expect(find.text('Dès que possible'), findsOneWidget);
      expect(ad, findsOneWidget); // consultation : bannière autorisée
      await tapK(tester, 'request-cancel');
      await tapK(tester, 'request-cancel-keep');
      expect(reqs.calls, isNot(contains('cancel')));
      await tapK(tester, 'request-cancel');
      await tapK(tester, 'request-cancel-confirm');
      expect(reqs.calls, contains('cancel'));
      expect(find.text('Annulée'), findsOneWidget);
      expect(k('request-cancel'), findsNothing); // plus annulable
    });

    testWidgets('détail d’une demande déjà annulée : pas d’action', (tester) async {
      await pumpApp(tester, requests: FakeServiceRequestsRepository(items: [request(id: 'a', status: 'CANCELLED')]), location: '/requests/a');
      expect(k('request-cancel'), findsNothing);
    });
  });

  group('ACCESSIBILITÉ', () {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('320 dp · ×$scale · clavier ouvert : formulaire sans overflow, CTA atteignable', (tester) async {
        await startFromDiagnostic(tester, size: const Size(960, 1704), scale: scale);
        tester.view.viewInsets = const FakeViewPadding(bottom: 900); // clavier ouvert (pixels physiques)
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.showKeyboard(k('help-phone'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await see(tester, 'help-send');
        expect(tester.takeException(), isNull);
        expect(tester.getSize(k('help-send')).height, greaterThanOrEqualTo(48));
      });

      testWidgets('320 dp · ×$scale : dépannage, confirmation, détail', (tester) async {
        final reqs = FakeServiceRequestsRepository(items: [request(id: 'a', summary: 'Lave-vaisselle encastrable qui ne vidange plus depuis ce matin malgré le nettoyage du filtre', equipmentLabel: 'Lave-vaisselle Bosch Siemens')]);
        for (final loc in ['/repair', '/help/a/done', '/requests/a']) {
          await pumpApp(tester, requests: reqs, size: const Size(960, 1704), textScale: scale, location: loc);
          expect(tester.takeException(), isNull, reason: loc);
        }
      });
    }

    testWidgets('cibles tactiles ≥ 48 dp : puces, médias, consentement', (tester) async {
      await startFromDiagnostic(tester);
      for (final key in ['help-when-asap', 'help-consent', 'help-media-m1', 'help-send']) {
        await see(tester, key);
        expect(tester.getSize(k(key)).height, greaterThanOrEqualTo(48), reason: key);
      }
    });

    testWidgets('lecteur d’écran : puces annoncées comme sélectionnées (pas seulement par la couleur)', (tester) async {
      final handle = tester.ensureSemantics();
      await startFromDiagnostic(tester);
      await tapK(tester, 'help-when-asap');
      expect(tester.getSemantics(find.text('Dès que possible')).flagsCollection.isSelected, isNotNull);
      expect(find.byIcon(Icons.check_rounded), findsWidgets); // indication visuelle non colorée
      handle.dispose();
    });
  });

  areaTests();
}

// ── Zone pilote : service d'intervention uniquement ─────────────────────────────────────────────
void areaTests() {
  const out = AreaCheck(status: 'out_of_zone');

  group('ZONE DE SERVICE', () {
    testWidgets('note discrète « Lyon et dans un rayon de 50 km » (valeurs du serveur), sans limiter Nalvium', (tester) async {
      await startFromDiagnostic(tester);
      expect(find.text('Service actuellement disponible à Lyon et dans un rayon de 50 km.'), findsOneWidget);
      expect(find.textContaining('Nalvium est disponible uniquement'), findsNothing);
    });

    testWidgets('dans la zone : le parcours continue exactement comme avant', (tester) async {
      final reqs = await startFromDiagnostic(tester);
      await fillContact(tester);
      await tapK(tester, 'help-when-asap');
      await tapK(tester, 'help-consent');
      await tapK(tester, 'help-send');
      expect(k('ooz-title'), findsNothing);
      expect(k('help-done-title'), findsOneWidget);
      expect(writes(reqs), ['from-session', 'update', 'media', 'submit']);
      expect(reqs.areaChecks, isNotEmpty);
    });

    testWidgets('hors zone (en quittant le champ) : écran dédié, rien d\'envoyé, aucune confirmation d\'intervention', (tester) async {
      final reqs = FakeServiceRequestsRepository(draftContext: Map<String, dynamic>.of(_ctx))..areaByPostal['38000'] = out;
      await startFromDiagnostic(tester, requests: reqs);
      await typeK(tester, 'help-first', 'Camille');
      await typeK(tester, 'help-phone', '06 12 34 56 78');
      await typeK(tester, 'help-city', 'Grenoble');
      await typeK(tester, 'help-postal', '38000');
      await tapK(tester, 'help-first'); // quitter le champ code postal
      expect(k('ooz-title'), findsOneWidget);
      expect(find.text('Nalvium arrive bientôt dans votre secteur'), findsOneWidget);
      expect(find.text('Les interventions sont actuellement disponibles à Lyon et dans un rayon de 50 km. Vous pouvez continuer à utiliser gratuitement le diagnostic Nalvium.'), findsOneWidget);
      expect(find.textContaining('arrive'), findsOneWidget);
      expect(find.textContaining('garanti'), findsNothing);
      expect(find.textContaining('envoyée'), findsNothing);
      expect(ad, findsNothing);
      expect(writes(reqs), ['from-session']); // aucune écriture, aucun envoi
    });

    testWidgets('hors zone à l\'envoi : écran dédié, pas de update/submit ; « Retour » conserve la saisie', (tester) async {
      final reqs = FakeServiceRequestsRepository(draftContext: Map<String, dynamic>.of(_ctx))..areaByPostal['38000'] = out;
      await startFromDiagnostic(tester, requests: reqs);
      await fillContact(tester, postal: '38000');
      await tapK(tester, 'help-when-asap');
      await tapK(tester, 'help-consent');
      await tapK(tester, 'help-send');
      expect(k('ooz-title'), findsOneWidget);
      expect(writes(reqs), ['from-session']);
      await tapK(tester, 'ooz-back');
      expect(tester.widget<TextField>(k('help-first')).controller!.text, 'Camille');
      expect(tester.widget<TextField>(k('help-postal')).controller!.text, '38000');
    });

    testWidgets('depuis un diagnostic : « Continuer avec Nalvium » revient au diagnostic, intact', (tester) async {
      final reqs = FakeServiceRequestsRepository(draftContext: Map<String, dynamic>.of(_ctx))..areaByPostal['38000'] = out;
      await startFromDiagnostic(tester, requests: reqs);
      await fillContact(tester, postal: '38000');
      await tapK(tester, 'help-when-asap');
      await tapK(tester, 'help-consent');
      await tapK(tester, 'help-send');
      await tapK(tester, 'ooz-continue');
      expect(find.text('Q ?'), findsOneWidget); // le diagnostic est toujours là
      expect(k('ask-for-help'), findsOneWidget);
      expect(reqs.items, isEmpty); // aucune demande
    });

    testWidgets('depuis Dépannage : « Continuer avec Nalvium » → accueil ; aucune demande listée', (tester) async {
      final reqs = FakeServiceRequestsRepository()..areaByPostal['38000'] = out;
      await pumpApp(tester, requests: reqs, location: '/repair');
      await tapK(tester, 'repair-ask');
      await typeK(tester, 'help-summary', 'Mon volet roulant est bloqué');
      await fillContact(tester, postal: '38000');
      await tapK(tester, 'help-when-asap');
      await tapK(tester, 'help-consent');
      await tapK(tester, 'help-send');
      expect(k('ooz-title'), findsOneWidget);
      await tapK(tester, 'ooz-continue');
      expect(find.text('Un problème à la maison ?'), findsOneWidget);
      expect(reqs.items, isEmpty);
    });

    testWidgets('Safety Stop hors zone : la sécurité reste prioritaire, aucune fausse intervention', (tester) async {
      final ctx = {..._ctx, 'safety_stop_reason': 'Arrêtez-vous ici. Gaz : sortez et appelez le 112.'};
      final reqs = FakeServiceRequestsRepository(draftContext: ctx)..areaByPostal['38000'] = out;
      await pumpApp(tester, repo: FakeSessionsRepository(stored: sessionState(action: NextActionType.safetyStop, status: 'stopped', message: 'Arrêtez-vous ici. Gaz : sortez et appelez le 112.')), requests: reqs, location: '/session/s1');
      expect(find.text('Arrêtez-vous ici'), findsOneWidget);
      await tapK(tester, 'safety-find-pro');
      await fillContact(tester, postal: '38000');
      await tapK(tester, 'help-when-asap');
      await tapK(tester, 'help-consent');
      await tapK(tester, 'help-send');
      expect(k('ooz-safety'), findsOneWidget);
      expect(find.text("Nalvium ne peut actuellement pas organiser d'intervention dans votre secteur."), findsOneWidget);
      expect(k('ooz-emergency'), findsOneWidget);
      expect(find.textContaining('18 ou 112'), findsOneWidget);
      expect(find.textContaining('en cours'), findsNothing);
      await tapK(tester, 'ooz-continue');
      expect(find.text('Arrêtez-vous ici'), findsOneWidget); // retour à l'écran de sécurité
    });

    testWidgets('rejet serveur « out_of_zone » à l\'envoi (contrôle définitif) : même écran', (tester) async {
      final reqs = await startFromDiagnostic(tester);
      reqs.submitCode = const ApiHttpException(422, 'out_of_zone');
      await fillContact(tester);
      await tapK(tester, 'help-when-asap');
      await tapK(tester, 'help-consent');
      await tapK(tester, 'help-send');
      expect(k('ooz-title'), findsOneWidget);
      expect(reqs.items, isEmpty);
    });

    testWidgets('ville et code postal incohérents : message clair, pas d\'écran hors zone', (tester) async {
      final reqs = FakeServiceRequestsRepository(draftContext: Map<String, dynamic>.of(_ctx))..areaByPostal['75001'] = const AreaCheck(status: 'invalid', code: 'city_postal_mismatch');
      await startFromDiagnostic(tester, requests: reqs);
      await fillContact(tester, postal: '75001');
      await tapK(tester, 'help-when-asap');
      await tapK(tester, 'help-consent');
      await tapK(tester, 'help-send');
      expect(find.text('Cette ville et ce code postal ne correspondent pas.'), findsOneWidget);
      expect(k('ooz-title'), findsNothing);
      expect(writes(reqs), ['from-session']);
      await typeK(tester, 'help-postal', '69003'); // corriger efface l'erreur
      expect(find.text('Cette ville et ce code postal ne correspondent pas.'), findsNothing);
    });

    testWidgets('ville inconnue / code postal inconnu : erreurs propres', (tester) async {
      final reqs = FakeServiceRequestsRepository(draftContext: Map<String, dynamic>.of(_ctx))
        ..areaByPostal['69100'] = const AreaCheck(status: 'invalid', code: 'unknown_city')
        ..areaByPostal['95999'] = const AreaCheck(status: 'invalid', code: 'unknown_postal_code');
      await startFromDiagnostic(tester, requests: reqs);
      await fillContact(tester, postal: '69100');
      await tapK(tester, 'help-when-asap');
      await tapK(tester, 'help-consent');
      await tapK(tester, 'help-send');
      expect(find.text('Nous ne trouvons pas cette ville. Vérifiez son orthographe.'), findsOneWidget);
      await typeK(tester, 'help-postal', '95999');
      await tapK(tester, 'help-send');
      expect(find.text('Ce code postal est inconnu.'), findsOneWidget);
    });

    testWidgets('contrôle indisponible (réseau) : on ne bloque pas, le serveur décidera à l\'envoi', (tester) async {
      final reqs = await startFromDiagnostic(tester);
      reqs.areaError = const ApiNetworkException();
      await fillContact(tester);
      await tapK(tester, 'help-when-asap');
      await tapK(tester, 'help-consent');
      await tapK(tester, 'help-send');
      expect(k('help-done-title'), findsOneWidget);
    });

    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('écran hors zone 320 dp · ×$scale (sécurité) sans overflow, CTA atteignable', (tester) async {
        final ctx = {..._ctx, 'safety_stop_reason': 'Arrêtez-vous ici. Gaz : sortez et appelez le 112.'};
        final reqs = FakeServiceRequestsRepository(draftContext: ctx)..areaByPostal['38000'] = out;
        await pumpApp(
          tester,
          repo: FakeSessionsRepository(stored: sessionState(action: NextActionType.safetyStop, status: 'stopped', message: 'Arrêtez-vous ici. Gaz : sortez.')),
          requests: reqs,
          size: const Size(960, 1704),
          textScale: scale,
          location: '/session/s1',
        );
        await tapK(tester, 'safety-find-pro');
        await fillContact(tester, postal: '38000');
        await tapK(tester, 'help-when-asap');
        await tapK(tester, 'help-consent');
        await tapK(tester, 'help-send');
        expect(tester.takeException(), isNull);
        await see(tester, 'ooz-continue');
        expect(tester.getSize(k('ooz-continue')).height, greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
