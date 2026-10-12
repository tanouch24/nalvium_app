import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/domain/diagnosis.dart';
import 'package:nalvium/domain/session.dart';
import 'package:nalvium/features/share/share_card.dart';
import 'package:nalvium/services/photo_capture_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

Finder k(String key) => find.byKey(Key(key));

Future<void> show(WidgetTester t, String key) async {
  await t.scrollUntilVisible(k(key), 150, scrollable: find.byType(Scrollable).hitTestable().first);
  await t.pumpAndSettle();
}

Future<void> tapK(WidgetTester t, String key) async {
  await show(t, key);
  await t.tap(k(key));
  await t.pumpAndSettle();
}

SessionState _resolved({String? mediaId = 'm1'}) =>
    sessionState(action: NextActionType.resolved, status: 'resolved', message: 'Parfait, la fuite est réglée.', mediaId: mediaId);

Map<String, Object> _after(String path) => {'nalvium.after_photos': jsonEncode({'s1': path})};

void main() {
  group('« C\'est réglé »', () {
    testWidgets('« Prenez une photo du résultat » : gardée sur le téléphone, avant / après affiché', (tester) async {
      final path = tempPhotoPath('after');
      final share = FakeShareService();
      final camera = await pumpApp(
        tester,
        repo: FakeSessionsRepository(stored: _resolved()),
        location: '/session/s1',
        captures: [CapturedPhoto(path)],
        share: share,
      );
      expect(k('resolved-title'), findsOneWidget);
      await tapK(tester, 'after-photo-take');
      expect(camera.calls, 1);
      expect(k('after-photo-saved'), findsOneWidget);
      expect(k('before-after'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(jsonDecode(prefs.getString('nalvium.after_photos')!), {'s1': path});
      // Rien n'est partagé tant que l'utilisateur ne le demande pas.
      expect(share.rendered, isEmpty);
      expect(share.shared, isEmpty);
    });

    testWidgets('appareil photo annulé : rien n\'est enregistré', (tester) async {
      await pumpApp(tester, repo: FakeSessionsRepository(stored: _resolved()), location: '/session/s1', captures: [null]);
      await tapK(tester, 'after-photo-take');
      expect(k('before-after'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('nalvium.after_photos'), isNull);
    });

    testWidgets('« Partager l\'avant / après » : carte avec les deux photos, seulement après l\'appui', (tester) async {
      final share = FakeShareService();
      await pumpApp(
        tester,
        repo: FakeSessionsRepository(stored: _resolved()),
        location: '/session/s1',
        prefs: _after(tempPhotoPath('after2')),
        share: share,
      );
      expect(share.rendered, isEmpty);
      await tapK(tester, 'share-before-after');
      expect(share.rendered.single, isA<BeforeAfterShareCard>());
      final card = share.rendered.single as BeforeAfterShareCard;
      expect((card.beforeLabel, card.afterLabel), ('Avant', 'Après'));
      expect(card.title, 'Fuite sous l\'évier');
      expect(share.shared.single.fileName, 'nalvium-avant-apres.png');
    });

    testWidgets('sans photo « avant » : l\'après seul, pas de carte avant / après', (tester) async {
      await pumpApp(
        tester,
        repo: FakeSessionsRepository(stored: _resolved(mediaId: null)),
        location: '/session/s1',
        prefs: _after(tempPhotoPath('after3')),
      );
      await show(tester, 'after-photo-done');
      expect(k('before-after'), findsOneWidget);
      expect(k('share-before-after'), findsNothing);
    });
  });

  testWidgets('carte « Avant / après » : titre très long, sans photo décodée, aucun débordement', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox.fromSize(
            size: kShareCardSize,
            child: BeforeAfterShareCard(
              lead: 'Réparé avec Nalvium',
              title: 'Fuite sous l\'évier de la cuisine au niveau du siphon et du flexible ' * 3,
              beforeLabel: 'Avant',
              afterLabel: 'Après',
              disclaimer: 'Photos partagées par la personne qui a fait la réparation.',
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Avant'), findsOneWidget);
    expect(find.text('Après'), findsOneWidget);
  });

  group('récapitulatif et historique', () {
    testWidgets('récapitulatif : avant / après en tête et bouton de partage', (tester) async {
      await pumpApp(
        tester,
        repo: FakeSessionsRepository(stored: _resolved()),
        location: '/session/s1/summary',
        prefs: _after(tempPhotoPath('after4')),
      );
      expect(k('before-after'), findsOneWidget);
      await show(tester, 'share-before-after');
      expect(k('share-before-after'), findsOneWidget);
    });

    testWidgets('récapitulatif résolu sans photo « après » : la proposition est là', (tester) async {
      await pumpApp(tester, repo: FakeSessionsRepository(stored: _resolved()), location: '/session/s1/summary');
      expect(k('before-after'), findsNothing);
      await show(tester, 'after-photo-take');
      expect(k('after-photo-take'), findsOneWidget);
    });

    testWidgets('arrêt de sécurité : ni photo « après », ni avant / après, ni partage', (tester) async {
      final stop = sessionState(
        action: NextActionType.safetyStop,
        status: 'stopped',
        message: 'Arrêtez-vous ici. Odeur de gaz : sortez et appelez le 112.',
        mediaId: 'm1',
      );
      await pumpApp(tester, repo: FakeSessionsRepository(stored: stop), location: '/session/s1/summary', prefs: _after(tempPhotoPath('after5')));
      expect(k('before-after'), findsNothing);
      expect(k('after-photo-take'), findsNothing);
      expect(k('share-before-after'), findsNothing);
    });

    testWidgets('historique : vignette avant / après pour une réparation réussie', (tester) async {
      final repo = FakeSessionsRepository(sessions: [summary(id: 's1', status: 'resolved', state: 'RESOLVED')]);
      await pumpApp(tester, repo: repo, location: '/history', prefs: _after(tempPhotoPath('after6')));
      expect(k('history-before-after-s1'), findsOneWidget);
    });

    testWidgets('« Supprimer mes données » efface aussi les photos « après » du téléphone', (tester) async {
      await pumpApp(tester, location: '/settings/data/delete', prefs: _after(tempPhotoPath('after7')));
      await tapK(tester, 'delete-check');
      await tapK(tester, 'delete-confirm');
      expect(k('delete-done'), findsOneWidget);
      expect((await SharedPreferences.getInstance()).getString('nalvium.after_photos'), isNull);
    });
  });
}
