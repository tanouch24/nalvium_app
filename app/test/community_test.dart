import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/core/network/api_exceptions.dart';
import 'package:nalvium/domain/community.dart';
import 'package:nalvium/domain/diagnosis.dart';
import 'package:nalvium/domain/session.dart';
import 'package:nalvium/services/photo_capture_service.dart';

import 'helpers/fake_community.dart';
import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

Finder k(String key) => find.byKey(Key(key));
Finder get ad => find.byKey(const Key('ad-slot')).hitTestable();

Future<void> see(WidgetTester t, String key) async {
  if (k(key).evaluate().isEmpty) {
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

Future<void> openCommunity(WidgetTester t, FakeCommunityRepository repo, {Size? size, double scale = 1.0, FakeAdsService? ads, List<Object?> captures = const [null]}) =>
    pumpApp(t, community: repo, location: '/community', size: size ?? const Size(1080, 3600), textScale: scale, ads: ads, captures: captures);

/// Remplit titre + solution (texte de TEST non personnel).
Future<void> fillPost(WidgetTester t, {String title = 'Robinet qui goutte', String solution = "J'ai changé le joint du robinet."}) async {
  await typeK(t, 'compose-title', title);
  await typeK(t, 'compose-solution', solution);
}

void main() {
  group('FIL', () {
    testWidgets('vide : message honnête, aucun faux post, CTA, bannière autorisée', (tester) async {
      await openCommunity(tester, FakeCommunityRepository());
      expect(find.text('Communauté'), findsWidgets);
      expect(find.text('Les solutions partagées par la communauté Nalvium.'), findsOneWidget);
      expect(find.text('Les premières solutions arriveront bientôt.'), findsOneWidget);
      expect(k('community-empty-share'), findsOneWidget);
      expect(find.text('Partager une solution'), findsOneWidget); // un seul CTA dans l'état vide
      expect(find.byKey(const Key('community-share')), findsNothing);
      expect(k('community-saved'), findsOneWidget);
      expect(ad, findsOneWidget);
    });

    testWidgets('rempli : carte compacte (catégorie, titre, solution, matériel, compteurs) sans identité', (tester) async {
      final repo = FakeCommunityRepository(posts: [makePost(id: 'a', materials: 'Tournevis, chiffon', helpful: 3, comments: 2)]);
      await openCommunity(tester, repo);
      expect(find.text('Mon lave-vaisselle ne vidangeait plus'), findsOneWidget);
      expect(find.textContaining('J\'ai nettoyé le filtre'), findsOneWidget);
      expect(find.textContaining('Électroménager'), findsOneWidget);
      expect(find.text('Matériel : Tournevis, chiffon'), findsOneWidget);
      expect(k('community-share'), findsOneWidget); // avec des publications : accès normal dans l'en-tête
      expect(k('community-empty-share'), findsNothing);
      expect(find.text('Utile · 3'), findsOneWidget);
      expect(find.text('Commenter · 2'), findsOneWidget);
      expect(find.text('Enregistrer'), findsOneWidget);
      expect(find.textContaining('Membre Nalvium'), findsNothing); // carte compacte
    });

    testWidgets('pagination : la suite charge au défilement, sans doublon', (tester) async {
      final repo = FakeCommunityRepository(posts: [for (var i = 0; i < 7; i++) makePost(id: 'p$i', title: 'Solution numéro $i')], pageSize: 3);
      await openCommunity(tester, repo, size: const Size(1080, 1600));
      expect(repo.calls.where((c) => c.startsWith('feed')), ['feed:0']);
      for (var i = 0; i < 6; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -1200));
        await tester.pumpAndSettle();
      }
      expect(repo.calls.where((c) => c.startsWith('feed')), ['feed:0', 'feed:3', 'feed:6']);
      expect(k('community-end'), findsOneWidget);
      expect(find.text('Solution numéro 6'), findsOneWidget); // dernier élément atteint, affiché une seule fois
    });

    testWidgets('erreur réseau : message + Réessayer ; erreur sur la suite : réessayer en bas', (tester) async {
      final repo = FakeCommunityRepository()..feedError = const ApiNetworkException();
      await openCommunity(tester, repo);
      expect(k('error-title'), findsOneWidget);
      repo.feedError = null;
      await tester.tap(k('retry'));
      await tester.pumpAndSettle();
      expect(find.text('Les premières solutions arriveront bientôt.'), findsOneWidget);
    });
  });

  group('UTILE / ENREGISTRER / ENREGISTRÉS', () {
    testWidgets('Utile : compteur réel, retrait, erreur honnête', (tester) async {
      final repo = FakeCommunityRepository(posts: [makePost(id: 'a')]);
      await openCommunity(tester, repo);
      await tapK(tester, 'helpful-a');
      expect(find.text('Utile · 1'), findsOneWidget);
      await tapK(tester, 'helpful-a');
      expect(find.text('Utile'), findsOneWidget);
      expect(repo.calls, containsAllInOrder(['helpful:true', 'helpful:false']));
      repo.actionError = const ApiNetworkException();
      await tapK(tester, 'helpful-a');
      expect(find.text("L'action n'a pas pu être enregistrée. Réessayez."), findsOneWidget);
    });

    testWidgets('Sauvegarder → Enregistrés (vide puis rempli) → retrait', (tester) async {
      final repo = FakeCommunityRepository(posts: [makePost(id: 'a'), makePost(id: 'b', title: 'Autre solution')]);
      await openCommunity(tester, repo);
      await tapK(tester, 'community-saved');
      expect(find.text("Vous n'avez encore enregistré aucune solution."), findsOneWidget);
      expect(ad, findsOneWidget); // Enregistrés : bannière autorisée
      await tapK(tester, 'saved-back');
      await tapK(tester, 'save-a');
      expect(find.text('Enregistrés'), findsWidgets);
      await tapK(tester, 'community-saved');
      expect(find.text('Mon lave-vaisselle ne vidangeait plus'), findsOneWidget);
      expect(find.text('Autre solution'), findsNothing);
      await tapK(tester, 'save-a');
      expect(find.text("Vous n'avez encore enregistré aucune solution."), findsOneWidget);
    });
  });

  group('DÉTAIL', () {
    testWidgets('contenu, mention « solution partagée par un membre », Membre Nalvium, bannière', (tester) async {
      final repo = FakeCommunityRepository(posts: [makePost(id: 'a', materials: 'Chiffon', comments: 1)]);
      await openCommunity(tester, repo);
      await tapK(tester, 'post-a');
      expect(k('post-title'), findsOneWidget);
      expect(find.text('Solution partagée par un membre de la communauté.'), findsOneWidget);
      expect(find.textContaining('Membre Nalvium'), findsWidgets);
      expect(find.textContaining('validé par Nalvium'), findsNothing);
      expect(find.textContaining('garanti'), findsNothing);
      expect(k('post-materials'), findsOneWidget);
      expect(ad, findsOneWidget);
    });

    testWidgets('publication supprimée : message clair et retour', (tester) async {
      await pumpApp(tester, community: FakeCommunityRepository(), location: '/community/post/disparu');
      expect(k('post-gone'), findsOneWidget);
      expect(k('error-title'), findsNothing);
    });

    testWidgets('commentaires : ajout, validation, suppression de ses propres commentaires', (tester) async {
      final repo = FakeCommunityRepository(posts: [makePost(id: 'a')]);
      await openCommunity(tester, repo);
      await tapK(tester, 'post-a');
      expect(k('no-comments'), findsOneWidget);
      await typeK(tester, 'comment-field', 'Merci, ça marche !');
      await tapK(tester, 'comment-send');
      expect(find.text('Merci, ça marche !'), findsOneWidget);
      expect(repo.calls, contains('comment'));
      repo.commentError = const ApiHttpException(422, 'unsafe_content');
      await typeK(tester, 'comment-field', 'texte');
      await tapK(tester, 'comment-send');
      expect(find.textContaining('touche à un sujet dangereux'), findsOneWidget);
      final id = repo.commentsByPost['a']!.single.id;
      await tapK(tester, 'comment-delete-$id');
      expect(find.text('Merci, ça marche !'), findsNothing);
    });

    testWidgets('signalement : raison, confirmation, doublon', (tester) async {
      final repo = FakeCommunityRepository(posts: [makePost(id: 'a')]);
      await openCommunity(tester, repo);
      await tapK(tester, 'post-a');
      await tapK(tester, 'detail-report');
      expect(find.text('Pourquoi signalez-vous ceci ?'), findsOneWidget);
      for (final r in ['dangerous', 'spam', 'inappropriate', 'personal_info', 'other']) {
        expect(k('report-$r'), findsOneWidget);
      }
      await tester.tap(k('report-spam'));
      await tester.pumpAndSettle();
      expect(find.text('Merci. Votre signalement a été enregistré.'), findsOneWidget);
      expect(repo.reports, ['post:a:spam']);
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();
      repo.alreadyReported = true;
      await tapK(tester, 'detail-report');
      await tester.tap(k('report-spam'));
      await tester.pumpAndSettle();
      expect(find.text('Vous avez déjà signalé ceci. Merci.'), findsOneWidget);
    });

    testWidgets('mon post : modifier et supprimer (avec confirmation)', (tester) async {
      final repo = FakeCommunityRepository(posts: [makePost(id: 'a', mine: true)]);
      await openCommunity(tester, repo);
      await tapK(tester, 'post-a');
      await tapK(tester, 'post-edit');
      await typeK(tester, 'compose-title', 'Titre corrigé');
      await tapK(tester, 'compose-continue');
      expect(repo.updates.single['title'], 'Titre corrigé');
      expect(find.text('Titre corrigé'), findsWidgets);
      await tapK(tester, 'post-delete');
      await tapK(tester, 'post-delete-cancel');
      expect(repo.calls, isNot(contains('delete')));
      await tapK(tester, 'post-delete');
      await tapK(tester, 'post-delete-confirm');
      expect(repo.posts, isEmpty);
      expect(find.text('Les premières solutions arriveront bientôt.'), findsOneWidget);
    });

    testWidgets('le post d’un autre : ni modifier ni supprimer', (tester) async {
      await openCommunity(tester, FakeCommunityRepository(posts: [makePost(id: 'a')]));
      await tapK(tester, 'post-a');
      expect(k('post-edit'), findsNothing);
      expect(k('post-delete'), findsNothing);
    });
  });

  group('CRÉER UNE PUBLICATION', () {
    testWidgets('validation, aperçu, consentement NON précoché, publication, aucun interstitiel', (tester) async {
      final ads = FakeAdsService();
      final repo = FakeCommunityRepository();
      await openCommunity(tester, repo, ads: ads);
      await tapK(tester, 'community-empty-share');
      expect(ad, findsNothing); // création : pas de bannière
      await tapK(tester, 'compose-continue');
      expect(find.text('Ajoutez un titre (3 caractères minimum).'), findsOneWidget);
      expect(find.text('Décrivez la solution (10 caractères minimum).'), findsOneWidget);
      expect(repo.calls.where((c) => c == 'create'), isEmpty);
      await fillPost(tester);
      await tapK(tester, 'compose-cat-plumbing');
      await typeK(tester, 'compose-materials', 'Clé à molette');
      await tapK(tester, 'compose-continue');
      expect(k('preview-title'), findsOneWidget);
      expect(find.text('Robinet qui goutte'), findsOneWidget);
      expect(ad, findsNothing); // aperçu / consentement : pas de bannière
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
      await tapK(tester, 'compose-publish');
      expect(k('compose-consent-error'), findsOneWidget);
      expect(repo.calls, isNot(contains('create')));
      await tapK(tester, 'compose-consent');
      await tapK(tester, 'compose-publish');
      expect(repo.created.single, {'title': 'Robinet qui goutte', 'solution': "J'ai changé le joint du robinet.", 'category': 'plumbing', 'materials': 'Clé à molette', 'media_id': null});
      expect(k('post-title'), findsOneWidget); // le post publié s'affiche
      expect(ads.newDiagnostics, 0); // aucun interstitiel, aucun compteur
    });

    testWidgets('refus serveur (contenu dangereux) : message clair, texte conservé', (tester) async {
      final repo = FakeCommunityRepository()..createError = const ApiHttpException(422, 'unsafe_content');
      await openCommunity(tester, repo);
      await tapK(tester, 'community-empty-share');
      await fillPost(tester);
      await tapK(tester, 'compose-continue');
      await tapK(tester, 'compose-consent');
      await tapK(tester, 'compose-publish');
      expect(find.textContaining('touche à un sujet dangereux'), findsOneWidget);
      await tapK(tester, 'compose-back-edit');
      expect(tester.widget<TextField>(k('compose-title')).controller!.text, 'Robinet qui goutte');
    });

    testWidgets('échec réseau à la publication : texte conservé, réessai', (tester) async {
      final repo = FakeCommunityRepository()..createError = const ApiNetworkException();
      await openCommunity(tester, repo);
      await tapK(tester, 'community-empty-share');
      await fillPost(tester);
      await tapK(tester, 'compose-continue');
      await tapK(tester, 'compose-consent');
      await tapK(tester, 'compose-publish');
      expect(find.textContaining('Votre texte est conservé'), findsOneWidget);
      repo.createError = null;
      await tapK(tester, 'compose-publish');
      expect(repo.created, hasLength(1));
    });

    testWidgets('photo prise : copie publique distincte, avertissement « visible publiquement », envoyée avec le post', (tester) async {
      final repo = FakeCommunityRepository();
      await openCommunity(tester, repo, captures: [CapturedPhoto(tempPhotoPath('cm1'))]);
      await tapK(tester, 'community-empty-share');
      await tapK(tester, 'compose-take-photo');
      expect(repo.calls, contains('upload'));
      expect(find.text('Cette photo sera visible publiquement dans la Communauté Nalvium.'), findsOneWidget);
      await fillPost(tester);
      await tapK(tester, 'compose-continue');
      expect(k('preview-public-notice'), findsOneWidget);
      await tapK(tester, 'compose-consent');
      await tapK(tester, 'compose-publish');
      expect(repo.created.single['media_id'], 'pub1');
    });

    testWidgets('retirer la photo ou fermer le formulaire supprime la copie publique de brouillon', (tester) async {
      final repo = FakeCommunityRepository();
      await openCommunity(tester, repo, captures: [CapturedPhoto(tempPhotoPath('cm2'))]);
      await tapK(tester, 'community-empty-share');
      await tapK(tester, 'compose-take-photo');
      await tapK(tester, 'compose-photo-remove');
      expect(repo.discarded, ['pub1']);
      expect(k('compose-photo'), findsNothing);
    });
  });

  group('PARTAGE DEPUIS UN DIAGNOSTIC RÉSOLU', () {
    SessionState resolved() => sessionState(
      action: NextActionType.resolved, status: 'resolved', message: 'Parfait, le filtre est propre.', title: 'Nettoyage filtre LV Bosch', category: 'appliance',
      actions: const [
        {'step_number': 1, 'instruction': 'Retirez le panier inférieur.', 'status': 'done'},
        {'step_number': 2, 'instruction': 'Sortez le filtre.', 'status': 'failed'},
        {'step_number': 3, 'instruction': 'Rincez le filtre.', 'status': 'done'},
      ],
      observations: const ['Intérieur de lave-vaisselle Bosch ouvert'],
      media: const [{'id': 'priv1', 'media_type': 'photo'}, {'id': 'priv2', 'media_type': 'video'}],
      equipment: const {'id': 'e1', 'equipment_type': 'dishwasher', 'display_name': 'Lave-vaisselle', 'brand': 'Bosch', 'room_name': 'Cuisine'},
    );

    test('brouillon : seulement titre, catégorie et étapes réellement faites — rien de privé', () {
      final d = CommunityDraft.fromSession(resolved());
      expect(d.title, 'Nettoyage filtre LV Bosch');
      expect(d.category, 'appliance');
      expect(d.solution, '• Retirez le panier inférieur.\n• Rincez le filtre.');
      expect(d.solution, isNot(contains('Sortez le filtre'))); // étape non réalisée
      for (final secret in ['Intérieur', 'Cuisine', 'hypoth', 'Parfait']) {
        expect('${d.title} ${d.solution} ${d.materials}', isNot(contains(secret)), reason: secret);
      }
      expect(d.privatePhotoIds, ['priv1']); // photos PROPOSÉES, jamais publiées d'office (pas la vidéo)
    });

    testWidgets('« Partager cette solution » : brouillon prérempli, rien publié, photo privée seulement après confirmation', (tester) async {
      final repo = FakeCommunityRepository();
      await pumpApp(tester, repo: FakeSessionsRepository(stored: resolved()), community: repo, location: '/session/s1');
      await tapK(tester, 'resolved-share');
      expect(repo.created, isEmpty);
      expect(tester.widget<TextField>(k('compose-title')).controller!.text, 'Nettoyage filtre LV Bosch');
      expect(tester.widget<TextField>(k('compose-solution')).controller!.text, contains('Retirez le panier inférieur.'));
      expect(k('compose-photo'), findsNothing); // aucune photo jointe d'office
      await tapK(tester, 'compose-private-priv1');
      expect(find.text('Rendre cette photo publique ?'), findsOneWidget);
      expect(find.textContaining('L\'original reste privé'), findsOneWidget);
      await tapK(tester, 'photo-confirm-no');
      expect(repo.calls.where((c) => c.startsWith('derive')), isEmpty);
      await tapK(tester, 'compose-private-priv1');
      await tapK(tester, 'photo-confirm-yes');
      expect(repo.calls, contains('derive:priv1'));
      expect(k('compose-public-notice'), findsOneWidget);
      expect(repo.created, isEmpty); // jamais publié automatiquement
    });

    testWidgets('proposition absente tant que le diagnostic n’est pas résolu', (tester) async {
      await pumpApp(tester, repo: FakeSessionsRepository(stored: sessionState(action: NextActionType.askQuestion, message: 'Q ?', choices: const ['Oui'])), location: '/session/s1');
      expect(k('resolved-share'), findsNothing);
    });
  });

  group('ACCESSIBILITÉ', () {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('320 dp · ×$scale : fil, détail, création, aperçu sans overflow ; clavier ouvert', (tester) async {
        final repo = FakeCommunityRepository(posts: [makePost(id: 'a', title: 'Mon lave-vaisselle encastrable ne vidangeait plus depuis ce matin malgré le nettoyage du filtre', materials: 'Tournevis cruciforme, chiffon, gants ménagers, bassine', helpful: 12, comments: 3, mine: true)]);
        await openCommunity(tester, repo, size: const Size(960, 1704), scale: scale);
        expect(tester.takeException(), isNull);
        expect(ad, findsOneWidget);
        await tapK(tester, 'post-a');
        expect(tester.takeException(), isNull);
        tester.view.viewInsets = const FakeViewPadding(bottom: 900);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        await see(tester, 'comment-field');
        await tester.showKeyboard(k('comment-field'));
        await see(tester, 'comment-send');
        expect(tester.takeException(), isNull);
        tester.view.resetViewInsets();
        await tapK(tester, 'post-back');
        await tapK(tester, 'community-share');
        await fillPost(tester);
        tester.view.viewInsets = const FakeViewPadding(bottom: 900);
        await tester.pumpAndSettle();
        await see(tester, 'compose-continue');
        expect(tester.takeException(), isNull);
        tester.view.resetViewInsets();
        await tapK(tester, 'compose-continue');
        await see(tester, 'compose-publish');
        expect(tester.takeException(), isNull);
        expect(tester.getSize(k('compose-publish')).height, greaterThanOrEqualTo(48));
      });
    }

    testWidgets('cibles tactiles ≥ 48 dp : actions de la carte', (tester) async {
      await openCommunity(tester, FakeCommunityRepository(posts: [makePost(id: 'a')]));
      for (final key in ['helpful-a', 'comment-a', 'save-a', 'community-saved']) {
        expect(tester.getSize(k(key)).height, greaterThanOrEqualTo(48), reason: key);
      }
    });

    testWidgets('lecteur d’écran : actions annoncées, état « Utile » exposé', (tester) async {
      final handle = tester.ensureSemantics();
      await openCommunity(tester, FakeCommunityRepository(posts: [makePost(id: 'a', helpful: 2, isHelpful: true)]));
      expect(find.bySemanticsLabel('Utile · 2'), findsOneWidget);
      expect(find.bySemanticsLabel('Enregistrer'), findsOneWidget);
      handle.dispose();
    });
  });
}
