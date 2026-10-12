import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/core/router/app_router.dart';
import 'package:nalvium/domain/home_profile.dart';
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

void main() {
  group('garde', () {
    test('démarrage non terminé : tout mène à /welcome, sauf les textes légaux', () {
      expect(appGuard(onboarded: false, aiConsent: false, location: '/home'), '/welcome');
      expect(appGuard(onboarded: false, aiConsent: false, location: '/welcome'), isNull);
      expect(appGuard(onboarded: false, aiConsent: false, location: '/settings/legal/privacy'), isNull);
    });
    test('sans accord IA : aucun nouveau diagnostic, le reste est libre', () {
      for (final loc in ['/capture/preview', '/video/capture', '/describe', '/analyze']) {
        expect(appGuard(onboarded: true, aiConsent: false, location: loc), '/consent', reason: loc);
      }
      for (final loc in ['/home', '/house', '/history', '/session/s1/summary']) {
        expect(appGuard(onboarded: true, aiConsent: false, location: loc), isNull, reason: loc);
      }
      expect(appGuard(onboarded: true, aiConsent: true, location: '/describe'), isNull);
    });
  });

  testWidgets('premier lancement : bienvenue → accord → « Plus tard » → profil → points vitaux → prêt → accueil', (tester) async {
    await pumpApp(
      tester,
      onboarded: false,
      aiConsent: false,
      guard: true,
      captures: [CapturedPhoto(tempPhotoPath('valve'))],
    );
    expect(k('ob-welcome'), findsOneWidget);
    await tapK(tester, 'ob-start');
    expect(k('consent-title'), findsOneWidget);
    expect(find.textContaining('OpenAI'), findsWidgets);
    await tapK(tester, 'consent-accept');

    // Moment wow proposé juste après l'accord ; « Plus tard » mène au profil de la maison.
    expect(k('ob-wow'), findsOneWidget);
    await tapK(tester, 'ob-wow-later');
    await tapK(tester, 'ob-apartment');
    await tapK(tester, 'ob-tenant');
    await tapK(tester, 'ob-gas');
    await tapK(tester, 'ob-skip'); // eau chaude : facultatif
    await tapK(tester, 'ob-handy');

    expect(k('ob-vitals'), findsOneWidget);
    await tapK(tester, 'vital-waterValve');
    expect(find.text('Photo ajoutée'), findsOneWidget);
    await tapK(tester, 'vital-gasMeter-absent');
    expect(find.text('Pas de gaz chez moi'), findsOneWidget);
    await tapK(tester, 'ob-vitals-continue');

    expect(k('ob-ready'), findsOneWidget);
    await tapK(tester, 'ob-go');
    expect(find.text('Un problème à la maison ?'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('nalvium.onboarded'), isTrue);
    expect(prefs.getString('nalvium.ai_consent'), isNotNull);
    final p = HomeProfile.fromJsonString(prefs.getString('nalvium.home_profile'));
    expect((p.housing, p.tenure, p.heating, p.hotWater, p.diyLevel), ('apartment', 'tenant', 'gas', null, 'handy'));
    expect(p.vitals[VitalPoint.waterValve]?.photoPath, isNotNull);
    expect(p.vitals[VitalPoint.gasMeter]?.absent, isTrue);
    expect(p.vitals[VitalPoint.electricalPanel], isNull);
  });

  testWidgets('bienvenue : le retour système quitte l\'app ; plus loin, il revient à l\'étape précédente', (tester) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call.method);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await pumpApp(tester, onboarded: false, aiConsent: false, guard: true);
    await tapK(tester, 'ob-start');
    expect(k('consent-title'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(k('ob-welcome'), findsOneWidget);
    expect(calls, isNot(contains('SystemNavigator.pop')));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(calls, contains('SystemNavigator.pop'));
  });

  testWidgets('tout passer est possible ; refuser l\'accord n\'empêche pas d\'entrer', (tester) async {
    await pumpApp(tester, onboarded: false, aiConsent: false, guard: true);
    await tapK(tester, 'ob-start');
    await tapK(tester, 'consent-decline');
    for (var i = 0; i < 5; i++) {
      await tapK(tester, 'ob-skip');
    }
    await tapK(tester, 'ob-vitals-later');
    await tapK(tester, 'ob-go');
    expect(find.text('Un problème à la maison ?'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('nalvium.ai_consent'), isNull);
  });

  testWidgets('sans accord : « Prendre une photo » et Scanner demandent l\'accord AVANT d\'ouvrir la caméra', (tester) async {
    final camera = await pumpApp(tester, aiConsent: false, guard: true);
    await tapK(tester, 'take-photo');
    expect(k('consent-title'), findsOneWidget);
    expect(camera.calls, 0);
    await tapK(tester, 'consent-close');
    await tapK(tester, 'nav-camera');
    expect(k('consent-title'), findsOneWidget);
    expect(camera.calls, 0);
  });

  testWidgets('sans accord : « Décrire » ouvre l\'accord ; accepter puis relancer', (tester) async {
    await pumpApp(tester, aiConsent: false, guard: true);
    await tapK(tester, 'describe-problem');
    expect(k('consent-title'), findsOneWidget);
    await tapK(tester, 'consent-decline');
    expect(k('consent-required'), findsOneWidget);
    await tapK(tester, 'describe-problem');
    await tapK(tester, 'consent-accept');
    await tapK(tester, 'describe-problem');
    expect(k('describe-field'), findsOneWidget);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('320 dp × $scale : chaque étape sans overflow', (tester) async {
      await pumpApp(tester, onboarded: false, aiConsent: false, guard: true, size: const Size(960, 2400), textScale: scale);
      expect(tester.takeException(), isNull);
      await tapK(tester, 'ob-start');
      expect(tester.takeException(), isNull);
      await tapK(tester, 'consent-accept');
      expect(k('ob-wow'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tapK(tester, 'ob-wow-later');
      for (var i = 0; i < 5; i++) {
        expect(tester.takeException(), isNull);
        await tapK(tester, 'ob-skip');
      }
      expect(tester.takeException(), isNull);
      await tapK(tester, 'ob-vitals-later');
      expect(tester.takeException(), isNull);
    });
  }

  test('profil : lecture tolérante, score de suivi honnête', () {
    expect(HomeProfile.fromJsonString('pas du json').answered, 0);
    final now = DateTime(2026, 10, 8);
    const empty = HomeProfile();
    expect(homeFollowUpScore(empty, now), 0);
    final full = HomeProfile(
      housing: 'house', tenure: 'owner', heating: 'gas', hotWater: 'boiler', diyLevel: 'handy',
      vitals: {for (final v in VitalPoint.values) v: const VitalInfo(absent: true)},
      maintenanceDone: {for (final t in MaintenanceTask.forProfile(const HomeProfile(heating: 'gas', hotWater: 'boiler'))) t.id: now},
    );
    expect(homeFollowUpScore(full, now), 100);
    expect(MaintenanceTask.forProfile(full).first.mandatory, isTrue); // chaudière en premier
    final again = HomeProfile.fromJsonString(full.toJsonString());
    expect(again.maintenanceDone['boiler'], now);
    expect(again.vitals[VitalPoint.gasMeter]!.absent, isTrue);
  });

  testWidgets('Réglages : retirer l\'accord IA (avec confirmation), puis le redonner', (tester) async {
    await pumpApp(tester, location: '/settings', guard: true);
    await tapK(tester, 'st-ai-consent');
    await tapK(tester, 'ai-withdraw-cancel');
    expect(find.text('Donné'), findsOneWidget);
    await tapK(tester, 'st-ai-consent');
    await tapK(tester, 'ai-withdraw-confirm');
    expect(find.text('Non donné'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('nalvium.ai_consent'), isNull);
    await tapK(tester, 'st-ai-consent');
    expect(k('consent-title'), findsOneWidget);
  });
}
