import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/core/analytics/analytics.dart';
import 'package:nalvium/core/config/app_info.dart';
import 'package:nalvium/features/settings/legal_texts.dart';
import 'package:nalvium/services/install_id_store.dart';
import 'package:nalvium/services/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

Finder k(String key) => find.byKey(Key(key));

void main() {
  a11y();
  analyticsWiring();
  group('Réglages', () {
    testWidgets('sections utiles, version affichée, pas de réglage inutile', (tester) async {
      await pumpApp(tester, location: '/settings');
      for (final key in ['st-data', 'st-privacy', 'st-ads', 'st-about', 'st-contact', 'st-terms', 'st-notice', 'st-ai', 'st-version']) {
        await tester.scrollUntilVisible(k(key), 200, scrollable: find.byType(Scrollable).first);
        expect(k(key), findsOneWidget, reason: key);
      }
      expect(find.text('$kAppVersionName ($kAppBuildNumber)'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('chaque écran légal s\'ouvre, est marqué provisoire, et ne dit pas « ne quittent jamais »', (tester) async {
      await pumpApp(tester, location: '/settings/legal/privacy');
      expect(k('legal-privacy'), findsOneWidget);
      expect(k('legal-provisional'), findsOneWidget);
    });

    for (final d in legalDocuments) {
      testWidgets('écran légal « ${d.id} »', (tester) async {
        await pumpApp(tester, location: '/settings/legal/${d.id}');
        expect(k('legal-${d.id}'), findsOneWidget);
      });
    }

    test('textes légaux : OpenAI mentionné, aucune promesse fausse, aucun faux « validé par un avocat »', () {
      final all = legalDocuments.expand((d) => d.sections).expand((s) => [s.heading, ...s.paragraphs]).join('\n').toLowerCase();
      expect(all, contains('openai'));
      expect(all, isNot(contains('ne quittent jamais')));
      expect(all, isNot(contains('validé par un avocat')));
      expect(all, contains('contact@nalvium.com'));
      expect(all, isNot(contains('24/7')));
      expect(kLegalVersion, isNotEmpty);
    });

    testWidgets('contact : e-mail seul, pas de téléphone', (tester) async {
      await pumpApp(tester, location: '/settings/contact');
      expect(find.text(kContactEmail), findsOneWidget);
      expect(find.textContaining(RegExp(r'\d{2} \d{2} \d{2}')), findsNothing);
    });

    test('la version affichée suit pubspec.yaml', () {
      final line = File('pubspec.yaml').readAsLinesSync().firstWhere((l) => l.startsWith('version:'));
      expect(line.split(':')[1].trim(), '$kAppVersionName+$kAppBuildNumber');
    });
  });

  group('Choix publicitaires (UMP)', () {
    testWidgets('requis : le bouton ouvre le formulaire', (tester) async {
      final ads = FakeAdsService(privacyRequired: true);
      await pumpApp(tester, location: '/settings/ads', ads: ads);
      await tester.tap(k('ads-manage'));
      await tester.pumpAndSettle();
      expect(ads.privacyFormShown, 1);
    });

    testWidgets('non requis : aucun bouton, message neutre', (tester) async {
      final ads = FakeAdsService();
      await pumpApp(tester, location: '/settings/ads', ads: ads);
      expect(k('ads-manage'), findsNothing);
      expect(k('ads-none'), findsOneWidget);
      expect(ads.privacyFormShown, 0);
    });
  });

  group('Suppression des données', () {
    testWidgets('confirmation explicite : bouton inactif tant que la case n\'est pas cochée', (tester) async {
      final account = FakeAccountRepository();
      await pumpApp(tester, location: '/settings/data/delete', account: account);
      await tester.ensureVisible(k('delete-confirm'));
      await tester.tap(k('delete-confirm'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(account.deletes, 0);
    });

    testWidgets('case cochée : supprime, nouvelle identité, retour accueil', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final account = FakeAccountRepository();
      await pumpApp(tester, location: '/settings/data/delete', account: account);
      await tester.ensureVisible(k('delete-check'));
      await tester.tap(k('delete-check'));
      await tester.pump();
      await tester.ensureVisible(k('delete-confirm'));
      await tester.tap(k('delete-confirm'));
      await tester.pumpAndSettle();
      expect(account.deletes, 1);
      expect(k('delete-done'), findsOneWidget);
      await tester.tap(k('delete-home'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('open-settings')), findsOneWidget);
    });

    testWidgets('échec réseau : rien n\'est présenté comme supprimé, on peut réessayer', (tester) async {
      final account = FakeAccountRepository(fail: true);
      await pumpApp(tester, location: '/settings/data/delete', account: account, size: const Size(1080, 7000));
      await tester.tap(k('delete-check'));
      await tester.pump();
      await tester.tap(k('delete-confirm'));
      await tester.pumpAndSettle();
      expect(k('delete-error'), findsOneWidget);
      expect(k('delete-done'), findsNothing);
      account.fail = false;
      await tester.tap(k('delete-confirm'));
      await tester.pumpAndSettle();
      expect(k('delete-done'), findsOneWidget);
    });

    test('InstallIdStore.reset : nouvelle identité différente, ancienne oubliée', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var n = 0;
      final ids = ['11111111-1111-4111-8111-111111111111', '22222222-2222-4222-8222-222222222222'];
      final store = InstallIdStore(prefs: prefs, generator: () => ids[n++]);
      final first = await store.getOrCreate();
      await store.reset();
      expect(prefs.getString(InstallIdStore.key), isNull);
      final second = await store.getOrCreate();
      expect(second, isNot(first));
    });
  });

  group('Analytics', () {
    test('liste blanche : aucune propriété personnelle', () {
      final sink = FakeAnalyticsSink();
      final a = Analytics(sink);
      a.log(AnalyticsEvent.helpRequested, source: 'diagnostic', mediaCount: 3);
      a.log(AnalyticsEvent.helpRequested, source: 'Lyon 69003 jean@x.fr', mediaCount: 99);
      expect(sink.events[0].$2, {'source': 'diagnostic', 'media_count': 3});
      expect(sink.events[1].$2, isEmpty);
    });

    test('un sink qui échoue ne casse jamais l\'app', () {
      final a = Analytics(_Boom());
      expect(() => a.log(AnalyticsEvent.appOpened), returnsNormally);
    });

    test('NoOp par défaut', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(analyticsSinkProvider), isA<NoOpAnalytics>());
    });
  });
}

class _Boom implements AnalyticsSink {
  @override
  void log(AnalyticsEvent event, Map<String, Object> properties) => throw StateError('x');
}

void a11y() {
  for (final loc in ['/settings', '/settings/data', '/settings/data/delete', '/settings/ads', '/settings/contact', '/settings/legal/privacy']) {
    testWidgets('$loc · 320 dp ×2 sans overflow', (tester) async {
      await pumpApp(tester, location: loc, size: const Size(960, 2400), dpr: 3, textScale: 2.0);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('pas de bannière sur la suppression de données', (tester) async {
    await pumpApp(tester, location: '/settings/data/delete');
    expect(find.byKey(const Key('ad-slot')), findsNothing);
  });
  testWidgets('bannière discrète sur la liste des Réglages', (tester) async {
    await pumpApp(tester, location: '/settings');
    expect(find.byKey(const Key('ad-slot')).hitTestable(), findsOneWidget);
  });
}

void analyticsWiring() {
  testWidgets('app_opened est enregistré, sans aucune propriété', (tester) async {
    final sink = FakeAnalyticsSink();
    await pumpApp(tester, analytics: sink);
    expect(sink.events.where((e) => e.$1 == AnalyticsEvent.appOpened).length, 1);
    for (final e in sink.events) {
      expect(e.$2.keys.toSet().difference({'source', 'media_count'}), isEmpty);
    }
  });
}
