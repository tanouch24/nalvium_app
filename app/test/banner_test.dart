import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/core/ads/ad_config.dart';
import 'package:nalvium/core/ads/banner_policy.dart';
import 'package:nalvium/domain/diagnosis.dart';

import 'helpers/fake_home.dart';
import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

Finder k(String key) => find.byKey(Key(key));
const _ad = Key('ad-slot');

/// La bannière doit être RÉELLEMENT visible (pas seulement présente sous un autre écran).
Finder get ad => find.byKey(_ad).hitTestable();

void main() {
  group('BannerPolicy', () {
    test('autorisée : navigation et consultation', () {
      for (final p in ['/home', '/house', '/repair', '/community', '/history', '/settings', '/equipment/abc', '/session/abc/summary']) {
        expect(BannerPolicy.allowedFor(p), isTrue, reason: p);
      }
    });
    test('jamais : capture, aperçu, analyse, session active, saisie, formulaires', () {
      for (final p in [
        '/capture/preview', '/video/capture', '/video/preview', '/describe', '/analyze', '/session/abc',
        '/session/abc/house', '/equipment/add', '/equipment/identify', '/equipment/abc/edit',
      ]) {
        expect(BannerPolicy.allowedFor(p), isFalse, reason: p);
      }
    });
  });

  group('IDs AdMob', () {
    test('tests et builds debug : uniquement les IDs de TEST Google', () {
      expect(AdIds.usesProduction, isFalse);
      final ids = AdIds.forBuild();
      for (final id in [ids.banner, ids.interstitial, ids.appOpen]) {
        expect(id, startsWith('ca-app-pub-3940256099942544/'), reason: id);
      }
    });
    test('les blocs de production Nalvium existent mais ne servent qu’en release', () {
      expect(AdIds.production.banner, 'ca-app-pub-9787163762873138/7749641197');
      expect(AdIds.production.interstitial, 'ca-app-pub-9787163762873138/8092246961');
      expect(AdIds.production.appOpen, 'ca-app-pub-9787163762873138/1479657021');
    });
  });

  group('Emplacements', () {
    final home = FakeHomeRepository(items: [equipment(id: 'a', brand: 'Bosch')]);

    testWidgets('Accueil, Maison, Dépannage, Communauté : bannière au-dessus de la navigation', (tester) async {
      await pumpApp(tester, home: home);
      for (final tab in ['nav-home', 'nav-house', 'nav-repair', 'nav-community']) {
        await tester.tap(k(tab));
        await tester.pumpAndSettle();
        expect(ad, findsOneWidget, reason: tab);
        expect(tester.getBottomLeft(ad).dy, lessThanOrEqualTo(tester.getTopLeft(k(tab)).dy), reason: tab);
      }
    });

    testWidgets('liste → fiche équipement → retour : bannière sur la fiche', (tester) async {
      await pumpApp(tester, home: home);
      await tester.tap(k('nav-house'));
      await tester.pumpAndSettle();
      await tester.tap(k('equipment-a'));
      await tester.pumpAndSettle();
      expect(ad, findsOneWidget);
      await tester.tap(k('equipment-edit'));
      await tester.pumpAndSettle();
      expect(ad, findsNothing); // formulaire : pas de bannière
    });

    testWidgets('formulaires et identification : jamais', (tester) async {
      await pumpApp(tester, home: home, location: '/equipment/add');
      expect(ad, findsNothing);
      await pumpApp(tester, home: home, location: '/equipment/identify');
      expect(ad, findsNothing);
    });

    testWidgets('récapitulatif d’un diagnostic terminé : oui', (tester) async {
      final repo = FakeSessionsRepository(stored: sessionState(action: NextActionType.resolved, status: 'resolved', message: 'Réglé.'));
      await pumpApp(tester, repo: repo, location: '/session/s1/summary');
      expect(ad, findsOneWidget);
    });

    testWidgets('PARCOURS : fiche équipement → diagnostic → aucune bannière → RESOLVED → retour Maison → bannière', (tester) async {
      final repo = FakeSessionsRepository(turns: [
        sessionState(action: NextActionType.askQuestion, message: 'Entendez-vous la pompe ?', choices: const ['Oui', 'Non']),
        sessionState(action: NextActionType.instruction, message: 'Ouvrez la porte.', choices: const ["C'est fait"]),
        sessionState(action: NextActionType.resolved, status: 'resolved', message: 'Réglé.'),
      ]);
      await pumpApp(tester, home: home, repo: repo);
      await tester.tap(k('nav-house'));
      await tester.pumpAndSettle();
      await tester.tap(k('equipment-a'));
      await tester.pumpAndSettle();
      expect(ad, findsOneWidget); // avant la session : bannière possible
      await tester.tap(k('equipment-diagnose'));
      await tester.pumpAndSettle();
      await tester.tap(k('diagnose-describe'));
      await tester.pumpAndSettle();
      expect(ad, findsNothing); // saisie
      await tester.enterText(k('describe-field'), 'Elle ne vidange plus');
      await tester.pumpAndSettle();
      await tester.tap(k('describe-continue'));
      await tester.pumpAndSettle();
      expect(find.text('Entendez-vous la pompe ?'), findsOneWidget);
      expect(ad, findsNothing); // ASK_QUESTION
      await tester.tap(find.text('Oui'));
      await tester.pumpAndSettle();
      expect(find.text('Ouvrez la porte.'), findsOneWidget);
      expect(ad, findsNothing); // INSTRUCTION
      await tester.tap(find.text("C'est fait"));
      await tester.pumpAndSettle();
      expect(k('resolved-title'), findsOneWidget);
      expect(ad, findsNothing); // RESOLVED : écran propre
      await tester.tap(k('resolved-finish'));
      await tester.pumpAndSettle();
      expect(ad, findsOneWidget); // retour sur un écran de consultation
    });
  });

  group('Mise en page', () {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('320 dp · ×$scale : bannière de 60 dp, rien n’est recouvert (liste Maison, CTA)', (tester) async {
        final home = FakeHomeRepository(items: [for (var i = 0; i < 6; i++) equipment(id: 'e$i', name: 'Équipement $i')]);
        await pumpApp(tester, home: home, size: const Size(960, 1704), textScale: scale, location: '/house');
        expect(tester.takeException(), isNull);
        // le dernier élément reste atteignable au-dessus de la bannière
        await tester.scrollUntilVisible(k('house-add'), 300, scrollable: find.byType(Scrollable).first);
        await tester.ensureVisible(k('house-add'));
        await tester.pumpAndSettle();
        expect(tester.getBottomLeft(k('house-add')).dy, lessThanOrEqualTo(tester.getTopLeft(ad).dy));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('no-fill : aucun espace réservé, aucune exception', (tester) async {
      final ads = FakeAdsService(banner: const SizedBox.shrink());
      await pumpApp(tester, ads: ads, home: FakeHomeRepository(), size: const Size(960, 1704), textScale: 2.0, location: '/house');
      expect(ad, findsNothing);
      expect(tester.takeException(), isNull);
      expect(k('house-add'), findsOneWidget);
    });

    testWidgets('chargement retardé : la bannière apparaît sans recouvrir le contenu', (tester) async {
      final ready = ValueNotifier(false);
      final ads = FakeAdsService(
        banner: ValueListenableBuilder<bool>(
          valueListenable: ready,
          builder: (_, loaded, _) => AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: DecoratedBox(key: loaded ? _ad : null, decoration: const BoxDecoration(color: Color(0xFFE3E9F2)), child: SizedBox(height: loaded ? 60 : 0, width: double.infinity)),
          ),
        ),
      );
      await pumpApp(tester, ads: ads, home: FakeHomeRepository(), size: const Size(960, 1704), location: '/house');
      expect(ad, findsNothing);
      ready.value = true;
      await tester.pumpAndSettle();
      expect(ad, findsOneWidget);
      await tester.ensureVisible(k('house-add')); // l'écran défile : le CTA reste atteignable au-dessus de la bannière
      await tester.pumpAndSettle();
      expect(tester.getBottomLeft(k('house-add')).dy, lessThanOrEqualTo(tester.getTopLeft(ad).dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('écran empilé (Historique) : bannière sous le contenu, dernier élément visible', (tester) async {
      final repo = FakeSessionsRepository(sessions: [for (var i = 0; i < 12; i++) summary(id: 's$i', title: 'Problème $i')]);
      await pumpApp(tester, repo: repo, size: const Size(960, 1704), textScale: 1.5, location: '/history');
      expect(ad, findsOneWidget);
      await tester.scrollUntilVisible(k('history-s11'), 300, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(tester.getBottomLeft(k('history-s11')).dy, lessThanOrEqualTo(tester.getTopLeft(ad).dy));
      expect(tester.takeException(), isNull);
    });
  });
}
