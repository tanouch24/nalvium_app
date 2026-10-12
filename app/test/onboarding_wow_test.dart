import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nalvium/domain/home_profile.dart';
import 'package:nalvium/features/capture/photo_preview_screen.dart';
import 'package:nalvium/services/photo_capture_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/pump_app.dart';

Finder k(String key) => find.byKey(Key(key));

Future<void> tapK(WidgetTester t, String key) async {
  await t.ensureVisible(k(key));
  await t.pumpAndSettle();
  await t.tap(k(key));
  await t.pumpAndSettle();
}

Future<void> toWow(WidgetTester tester) async {
  await tapK(tester, 'ob-start');
  await tapK(tester, 'consent-accept');
  expect(k('ob-wow'), findsOneWidget);
}

void main() {
  group('moment wow', () {
    testWidgets('accord → photo tout de suite : aperçu ouvert, démarrage terminé, carnet à compléter', (tester) async {
      final camera = await pumpApp(
        tester,
        onboarded: false,
        aiConsent: false,
        guard: true,
        captures: [CapturedPhoto(tempPhotoPath('wow'))],
      );
      await toWow(tester);
      await tapK(tester, 'ob-wow-photo');
      expect(camera.calls, 1);
      expect(find.byType(PhotoPreviewScreen), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('nalvium.onboarded'), isTrue);
      expect(prefs.getBool('nalvium.profile_pending'), isTrue);

      // Retour à l'accueil (après le premier résultat) : la carte « Complétez votre carnet » est là.
      GoRouter.of(tester.element(find.byType(PhotoPreviewScreen))).go('/home');
      await tester.pumpAndSettle();
      expect(k('dash-complete-profile'), findsOneWidget);
      expect(find.text('Complétez votre carnet maison (1 min)'), findsOneWidget);
    });

    testWidgets('appareil photo annulé : on reste sur l\'étape, rien n\'est marqué', (tester) async {
      await pumpApp(tester, onboarded: false, aiConsent: false, guard: true, captures: [null]);
      await toWow(tester);
      await tapK(tester, 'ob-wow-photo');
      expect(k('ob-wow'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('nalvium.onboarded'), isNull);
      expect(prefs.getBool('nalvium.profile_pending'), isNull);
    });

    testWidgets('« Décrire » ouvre la description ; « Filmer » ouvre la caméra vidéo', (tester) async {
      await pumpApp(tester, onboarded: false, aiConsent: false, guard: true);
      await toWow(tester);
      await tapK(tester, 'ob-wow-describe');
      expect(k('describe-field'), findsOneWidget);
    });

    testWidgets('« Filmer » ouvre la caméra vidéo', (tester) async {
      await pumpApp(tester, onboarded: false, aiConsent: false, guard: true);
      await toWow(tester);
      await tapK(tester, 'ob-wow-film');
      expect(k('camera-preview'), findsOneWidget);
    });

    testWidgets('accord refusé : pas de proposition de diagnostic, on passe au profil', (tester) async {
      await pumpApp(tester, onboarded: false, aiConsent: false, guard: true);
      await tapK(tester, 'ob-start');
      await tapK(tester, 'consent-decline');
      expect(k('ob-wow'), findsNothing);
      expect(k('ob-apartment'), findsOneWidget);
      // Le retour revient à l'accord, sans repasser par l'étape wow.
      await tapK(tester, 'ob-back');
      expect(k('consent-title'), findsOneWidget);
    });

    testWidgets('l\'accord IA reste AVANT l\'étape wow (aucun envoi possible sans accord)', (tester) async {
      await pumpApp(tester, onboarded: false, aiConsent: false, guard: true);
      await tapK(tester, 'ob-start');
      expect(k('consent-title'), findsOneWidget);
      expect(k('ob-wow'), findsNothing);
    });
  });

  group('carnet maison à compléter', () {
    testWidgets('la carte ouvre les questions du profil ; à la fin, elle disparaît', (tester) async {
      await pumpApp(tester, prefs: {'nalvium.profile_pending': true});
      await tapK(tester, 'dash-complete-profile');
      expect(k('ob-apartment'), findsOneWidget);
      expect(k('ob-wow'), findsNothing);
      await tapK(tester, 'ob-house');
      await tapK(tester, 'ob-owner');
      await tapK(tester, 'ob-gas');
      await tapK(tester, 'ob-boiler');
      await tapK(tester, 'ob-handy');
      expect(k('ob-vitals'), findsOneWidget);
      await tapK(tester, 'ob-vitals-later');
      expect(k('ob-ready'), findsOneWidget);
      await tapK(tester, 'ob-go');
      expect(k('dash-complete-profile'), findsNothing);
      expect(k('dash-follow-up'), findsOneWidget); // de retour sur l'accueil
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('nalvium.profile_pending'), isNull);
      final p = HomeProfile.fromJsonString(prefs.getString('nalvium.home_profile'));
      expect((p.housing, p.tenure, p.heating, p.hotWater, p.diyLevel), ('house', 'owner', 'gas', 'boiler', 'handy'));
    });

    testWidgets('retour depuis la première question : revient à l\'accueil, la carte reste', (tester) async {
      await pumpApp(tester, prefs: {'nalvium.profile_pending': true});
      await tapK(tester, 'dash-complete-profile');
      await tapK(tester, 'ob-back');
      expect(k('dash-complete-profile'), findsOneWidget);
    });

    testWidgets('masquable, et absente pour qui a suivi le démarrage complet', (tester) async {
      await pumpApp(tester, prefs: {'nalvium.profile_pending': true});
      await tapK(tester, 'dash-complete-profile-dismiss');
      expect(k('dash-complete-profile'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('nalvium.profile_pending'), isNull);
    });

    testWidgets('sans diagnostic lancé au démarrage : pas de carte', (tester) async {
      await pumpApp(tester);
      expect(k('dash-complete-profile'), findsNothing);
    });

    testWidgets('320 dp × 2 : carte « carnet » sans overflow', (tester) async {
      await pumpApp(tester, prefs: {'nalvium.profile_pending': true}, size: const Size(960, 2400), textScale: 2);
      await tester.scrollUntilVisible(k('dash-complete-profile'), 200, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
