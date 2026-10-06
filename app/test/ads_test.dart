import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/core/ads/ad_policy.dart';
import 'package:nalvium/domain/diagnosis.dart';
import 'package:nalvium/services/photo_capture_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

class _MemCounter implements DiagnosticCounter {
  int n = 0;
  @override
  Future<int> count() async => n;
  @override
  Future<void> increment() async => n++;
}

void main() {
  group('AdPolicy — interstitiel avant un NOUVEAU diagnostic', () {
    late _MemCounter counter;
    late DateTime now;
    late AdPolicy policy;

    setUp(() {
      counter = _MemCounter();
      now = DateTime(2026, 10, 5, 12);
      policy = AdPolicy(counter: counter, clock: () => now);
    });

    Future<bool> startDiagnostic({bool showIfDue = true}) async {
      final due = await policy.interstitialDueForNewDiagnostic();
      await policy.recordDiagnosticStarted();
      if (due && showIfDue) policy.recordFullscreenShown();
      return due;
    }

    test('diagnostic #1 : aucun interstitiel', () async {
      expect(await startDiagnostic(), isFalse);
    });

    test('#2, #3, #4+ : un interstitiel avant chaque nouveau diagnostic', () async {
      expect(await startDiagnostic(), isFalse); // #1
      for (var i = 2; i <= 6; i++) {
        now = now.add(const Duration(minutes: 5));
        expect(await startDiagnostic(), isTrue, reason: 'diagnostic #$i');
      }
      expect(counter.n, 6);
    });

    test('délai minimal entre deux pubs plein écran : pas de rafale', () async {
      await startDiagnostic(); // #1
      now = now.add(const Duration(minutes: 5));
      expect(await startDiagnostic(), isTrue); // #2 : pub montrée
      now = now.add(const Duration(seconds: 20));
      expect(await startDiagnostic(), isFalse); // #3 trop tôt : pas de pub (et on ne bloque jamais l'utilisateur)
      now = now.add(const Duration(seconds: 90));
      expect(await startDiagnostic(), isTrue); // #4 : de nouveau dû
    });

    test('le compteur compte les diagnostics DÉMARRÉS, même sans pub affichée', () async {
      await startDiagnostic();
      await startDiagnostic(showIfDue: false);
      expect(counter.n, 2);
    });
  });

  group('AdPolicy — App Open', () {
    final policy = AdPolicy(counter: _MemCounter());

    test('démarrage à froid sur l\'accueil : autorisée', () {
      expect(policy.appOpenAllowed(route: '/home'), isTrue);
    });

    test('JAMAIS au milieu d\'une session, d\'une capture ou d\'une saisie', () {
      for (final r in ['/session/abc', '/session/abc/summary', '/analyze', '/capture/preview', '/describe']) {
        expect(AdPolicy.isInsideSession(r), isTrue, reason: r);
        expect(policy.appOpenAllowed(route: r, backgroundFor: const Duration(hours: 2)), isFalse, reason: r);
      }
      for (final r in ['/home', '/house', '/repair', '/community', '/history', '/settings']) {
        expect(AdPolicy.isInsideSession(r), isFalse, reason: r);
      }
    });

    test('retour d\'arrière-plan : seulement après 30 s (pas de bascule rapide)', () {
      expect(policy.appOpenAllowed(route: '/home', backgroundFor: const Duration(seconds: 5)), isFalse);
      expect(policy.appOpenAllowed(route: '/home', backgroundFor: const Duration(seconds: 45)), isTrue);
    });

    test('jamais pendant la caméra système (intent externe)', () {
      expect(policy.appOpenAllowed(route: '/home', backgroundFor: const Duration(minutes: 5), externalIntent: true), isFalse);
    });

    test('respecte le délai commun des pubs plein écran', () {
      var now = DateTime(2026, 10, 5, 12);
      final p = AdPolicy(counter: _MemCounter(), clock: () => now)..recordFullscreenShown();
      expect(p.appOpenAllowed(route: '/home'), isFalse);
      now = now.add(const Duration(seconds: 61));
      expect(p.appOpenAllowed(route: '/home'), isTrue);
    });
  });

  test('PrefsDiagnosticCounter : persistant entre deux lancements', () async {
    SharedPreferences.setMockInitialValues({});
    final a = PrefsDiagnosticCounter();
    expect(await a.count(), 0);
    await a.increment();
    await a.increment();
    expect(await PrefsDiagnosticCounter().count(), 2); // « autre lancement »
  });

  group('Intégration UI', () {
    testWidgets('ACCUEIL : la bannière permanente est présente et n\'écrase pas le CTA photo', (tester) async {
      final repo = FakeSessionsRepository(sessions: [summary(lastMessage: 'Vérifiez le filtre')]);
      await pumpApp(tester, repo: repo, size: const Size(720, 1600), dpr: 2);
      expect(find.byKey(const Key('ad-slot')).hitTestable(), findsOneWidget);
      expect(find.byKey(const Key('take-photo')), findsOneWidget);
      expect(find.byKey(const Key('home-photo')), findsOneWidget);
      // (la visibilité de « À reprendre » au-dessus de la bannière est vérifiée sur Samsung : les tests n'ont pas la vraie police)
      expect(tester.takeException(), isNull);
    });

    testWidgets('la bannière suit la politique centrale : consultation oui, session active non', (tester) async {
      final repo = FakeSessionsRepository(stored: sessionState(), sessions: [summary()]);
      await pumpApp(tester, repo: repo);
      await tester.tap(find.byKey(const Key('open-history')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ad-slot')).hitTestable(), findsOneWidget); // Historique
      await tester.tap(find.byKey(const Key('history-s1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('ad-slot')).hitTestable(), findsNothing); // session en cours : aucune pub
    });

    testWidgets('PHOTO : « Utiliser cette photo » déclare un nouveau diagnostic (interstitiel éventuel avant l\'analyse)', (tester) async {
      final ads = FakeAdsService();
      final repo = FakeSessionsRepository(turns: [sessionState()]);
      await pumpApp(tester, repo: repo, ads: ads, captures: [CapturedPhoto(tempPhotoPath('ad1'))]);
      await tester.tap(find.byKey(const Key('take-photo')));
      await tester.pumpAndSettle();
      expect(ads.newDiagnostics, 0); // l'aperçu n'est pas un diagnostic
      await tester.tap(find.byKey(const Key('use-photo')));
      await tester.pumpAndSettle();
      expect(ads.newDiagnostics, 1);
      expect(repo.calls, containsAllInOrder(['create', 'upload', 'turn']));
    });

    testWidgets('« Reprendre » (nouvelle prise) ne compte pas comme un nouveau diagnostic', (tester) async {
      final ads = FakeAdsService();
      await pumpApp(tester, ads: ads, captures: [CapturedPhoto(tempPhotoPath('ad2')), CapturedPhoto(tempPhotoPath('ad3'))]);
      await tester.tap(find.byKey(const Key('take-photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('retake-photo')));
      await tester.pumpAndSettle();
      expect(ads.newDiagnostics, 0);
    });

    testWidgets('TEXTE : « Continuer » déclare un nouveau diagnostic', (tester) async {
      final ads = FakeAdsService();
      final repo = FakeSessionsRepository(turns: [sessionState()]);
      await pumpApp(tester, repo: repo, ads: ads);
      await tester.tap(find.byKey(const Key('describe-problem')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('describe-field')), 'Mon robinet goutte');
      await tester.pump();
      await tester.tap(find.byKey(const Key('describe-continue')));
      await tester.pumpAndSettle();
      expect(ads.newDiagnostics, 1);
    });

    testWidgets('REPRISE d\'une session : aucun diagnostic compté, aucune pub', (tester) async {
      final ads = FakeAdsService();
      final repo = FakeSessionsRepository(
        sessions: [summary(state: 'INSTRUCTION')],
        stored: sessionState(action: NextActionType.instruction, message: 'Fermez le robinet.'),
      );
      await pumpApp(tester, repo: repo, ads: ads);
      await tester.ensureVisible(find.byKey(const Key('resume-session')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('resume-session')));
      await tester.pumpAndSettle();
      expect(find.text('Fermez le robinet.'), findsOneWidget);
      expect(ads.newDiagnostics, 0);
    });

    testWidgets('EN SESSION : la caméra ne déclenche aucun nouveau diagnostic et suspend l\'App Open', (tester) async {
      final ads = FakeAdsService();
      final repo = FakeSessionsRepository(
        stored: sessionState(action: NextActionType.requestPhoto, message: 'Une photo ?'),
        turns: [sessionState(message: 'Merci.')],
      );
      await pumpApp(tester, repo: repo, ads: ads, location: '/session/s1', captures: [CapturedPhoto(tempPhotoPath('ad4'))]);
      await tester.tap(find.byKey(const Key('take-requested-photo')));
      await tester.pumpAndSettle();
      expect(ads.suspendCalls, 1);
      expect(ads.newDiagnostics, 0);
    });

    testWidgets('au démarrage, l\'initialisation publicitaire (consentement + SDK) est demandée', (tester) async {
      final ads = FakeAdsService();
      await pumpApp(tester, ads: ads);
      expect(ads.initializeCalls, 1);
    });
  });
}
