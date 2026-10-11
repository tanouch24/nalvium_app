import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/core/theme/nalvium_theme.dart';
import 'package:nalvium/domain/diagnosis.dart';
import 'package:nalvium/domain/estimate.dart';
import 'package:nalvium/domain/session.dart';
import 'package:nalvium/features/capture/analysis_wait.dart';
import 'package:nalvium/features/home/dashboard.dart';
import 'package:nalvium/features/session/estimate_card.dart';
import 'package:nalvium/features/share/share_card.dart';
import 'package:nalvium/l10n/app_localizations.dart';
import 'package:nalvium/services/photo_capture_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

Finder k(String key) => find.byKey(Key(key));

Future<void> show(WidgetTester t, String key) async {
  await t.scrollUntilVisible(k(key), 150, scrollable: find.byType(Scrollable).hitTestable().last);
  await t.pumpAndSettle();
}

Future<void> tapK(WidgetTester t, String key) async {
  await show(t, key);
  await t.tap(k(key));
  await t.pumpAndSettle();
}

Widget host(Widget child) => MaterialApp(
  theme: buildNalviumTheme(),
  locale: const Locale('fr'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

const _est = {
  'diy_feasibility': 8,
  'difficulty': 'easy',
  'duration_minutes': 20,
  'diy_cost_min': 5,
  'diy_cost_max': 12,
  'pro_cost_min': 120,
  'pro_cost_max': 180,
};

SessionSummary _resolved(String id, int proMin, int proMax) => SessionSummary(
  id: id,
  status: 'resolved',
  currentState: 'RESOLVED',
  updatedAt: DateTime(2026, 10, 1),
  estimate: RepairEstimate.maybe({..._est, 'pro_cost_min': proMin, 'pro_cost_max': proMax}),
);

/// Capte les retours haptiques envoyés au système.
List<String> recordHaptics(WidgetTester tester) {
  final haptics = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments as String);
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  return haptics;
}

void main() {
  // ── 1. CARTE À PARTAGER ─────────────────────────────────────────────
  group('partage du résultat', () {
    testWidgets('récapitulatif : « Partager » rend la carte et ouvre le partage avec un texte court', (tester) async {
      final share = FakeShareService();
      await pumpApp(
        tester,
        share: share,
        location: '/session/s1/summary',
        repo: FakeSessionsRepository(
          stored: sessionState(action: NextActionType.resolved, status: 'resolved', message: 'C\'est réglé.', estimate: _est),
        ),
      );
      await tapK(tester, 'share-result');
      expect(share.shared, hasLength(1));
      expect(share.shared.single.text, 'Diagnostiqué en 30 secondes avec Nalvium · nalvium.com');
      expect(share.shared.single.fileName, endsWith('.png'));
      final card = share.rendered.single as ResultShareCard;
      expect(card.title, 'Fuite sous l\'évier');
      expect(card.category, 'Plomberie');
      expect(card.verdict, DiyVerdict.diy);
      expect(card.yourself, '5–12 €');
      expect(card.pro, '120–180 €');
      expect(card.savings, 'Économie possible : 141 €');
      expect(card.disclaimer, 'Estimation indicative, pas un devis');
    });

    testWidgets('écran « C\'est réglé » : bouton « Partager » ; jamais pendant le guidage', (tester) async {
      await pumpApp(
        tester,
        location: '/session/s1',
        repo: FakeSessionsRepository(
          stored: sessionState(action: NextActionType.resolved, status: 'resolved', message: 'C\'est réglé.', estimate: _est),
        ),
      );
      await show(tester, 'share-result');
      expect(k('share-result'), findsOneWidget);
    });

    testWidgets('pendant une étape guidée : pas de partage', (tester) async {
      await pumpApp(
        tester,
        location: '/session/s1',
        repo: FakeSessionsRepository(stored: sessionState(action: NextActionType.instruction, estimate: _est)),
      );
      expect(k('estimate-card'), findsOneWidget);
      expect(k('share-result'), findsNothing);
    });

    testWidgets('arrêt de sécurité : ni estimation ni partage, même si le serveur en renvoie une', (tester) async {
      await pumpApp(
        tester,
        location: '/session/s1/summary',
        repo: FakeSessionsRepository(
          stored: sessionState(action: NextActionType.safetyStop, status: 'stopped', message: 'STOP : coupez le gaz.', estimate: _est),
        ),
      );
      expect(k('estimate-card'), findsNothing);
      expect(k('share-result'), findsNothing);
      expect(find.textContaining('€'), findsNothing);
    });

    testWidgets('sans estimation : pas de partage', (tester) async {
      await pumpApp(
        tester,
        location: '/session/s1/summary',
        repo: FakeSessionsRepository(stored: sessionState(action: NextActionType.resolved, status: 'resolved')),
      );
      expect(k('share-result'), findsNothing);
    });

    testWidgets('échec du partage : simple message, rien ne casse', (tester) async {
      await pumpApp(
        tester,
        share: FakeShareService(fail: true),
        location: '/session/s1/summary',
        repo: FakeSessionsRepository(stored: sessionState(action: NextActionType.resolved, status: 'resolved', estimate: _est)),
      );
      await tapK(tester, 'share-result');
      expect(k('share-failed'), findsOneWidget);
    });

    testWidgets('rendu réel : PNG portrait 1080 × 1350, sans débordement', (tester) async {
      final figtree = FontLoader('Figtree');
      for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
        figtree.addFont(rootBundle.load('assets/fonts/Figtree-$w.ttf'));
      }
      await tester.runAsync(figtree.load);
      late AppLocalizations l10n;
      await tester.pumpWidget(host(Builder(builder: (c) {
        l10n = AppLocalizations.of(c);
        return const SizedBox();
      })));
      final card = resultShareCardFor(l10n, sessionState(action: NextActionType.resolved, status: 'resolved', estimate: _est));
      final png = await tester.runAsync(() => renderShareCardPng(card, tester.view));
      // En-tête PNG : largeur et hauteur (IHDR, octets 16–23).
      final header = ByteData.sublistView(png!, 16, 24);
      expect(png.sublist(1, 4), 'PNG'.codeUnits);
      expect(header.getUint32(0), 1080);
      expect(header.getUint32(4), 1350);
      const savings = SavingsShareCard(lead: 'J\'ai économisé', amount: '1\u202f250 €', tail: 'sur mes dépannages avec Nalvium', disclaimer: 'x', milestone: 'Palier atteint : 1\u202f000 € économisés');
      final png2 = await tester.runAsync(() => renderShareCardPng(savings, tester.view));
      expect(ByteData.sublistView(png2!, 16, 24).getUint32(0), 1080);
    });

    testWidgets('pro recommandé : la carte ne montre ni coût « vous-même » ni économie', (tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(host(Builder(builder: (c) {
        l10n = AppLocalizations.of(c);
        return const SizedBox();
      })));
      final card = resultShareCardFor(
        l10n,
        sessionState(action: NextActionType.recommendProfessional, status: 'referred', estimate: _est),
      );
      expect(card.verdict, DiyVerdict.pro);
      expect(card.yourself, '—');
      expect(card.savings, isNull);
    });
  });

  // ── 2. ATTENTE NARRÉE ───────────────────────────────────────────────
  group('attente narrée', () {
    testWidgets('photo : étapes cochées une à une (clic léger), choc moyen à la vraie réponse', (tester) async {
      final haptics = recordHaptics(tester);
      final repo = FakeSessionsRepository(turns: [sessionState()])..turnGate = Completer<void>();
      await pumpApp(tester, repo: repo, captures: [CapturedPhoto(tempPhotoPath('x'))]);
      await tester.tap(k('take-photo'));
      await tester.pumpAndSettle();
      await tester.tap(k('use-photo'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 400));
      haptics.clear();
      for (final t in ['Lecture de votre photo…', 'Identification de l\'équipement…', 'Calcul du coût…', 'Vérification sécurité…']) {
        expect(find.text(t), findsOneWidget);
      }
      await tester.pump(kAnalysisStepEvery);
      await tester.pump(const Duration(milliseconds: 300));
      expect(k('analysis-step-0-done'), findsOneWidget);
      expect(haptics, ['HapticFeedbackType.selectionClick']);
      await tester.pump(const Duration(seconds: 20));
      expect(k('analysis-step-3-current'), findsOneWidget); // jamais « terminé » avant la réponse
      expect(haptics.where((h) => h.endsWith('selectionClick')), hasLength(3));
      haptics.clear();
      repo.turnGate!.complete();
      await tester.pumpAndSettle();
      expect(haptics, contains('HapticFeedbackType.mediumImpact'));
      expect(find.text('Question ?'), findsOneWidget);
    });

    testWidgets('description : la première étape lit la description', (tester) async {
      await tester.pumpWidget(host(AnalysisWait(onCancel: () {}, refined: true, steps: const ['Lecture de votre description…', 'b', 'c'])));
      expect(find.text('Lecture de votre description…'), findsOneWidget);
      expect(k('analysis-step-0-current'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('réduire les animations : liste statique, aucun indicateur qui tourne', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await tester.pumpWidget(host(AnalysisWait(onCancel: () {}, refined: true, steps: const ['a', 'b', 'c', 'd'])));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pumpAndSettle(); // rien ne boucle
      await tester.pumpWidget(const SizedBox());
    });
  });

  // ── 3. PASTILLE DE CONFIANCE ────────────────────────────────────────
  group('pastille de confiance', () {
    test('verdict : faisabilité, difficulté, recommandation d\'un pro', () {
      RepairEstimate e(int f, String d) => RepairEstimate(diyFeasibility: f, difficulty: d);
      expect(e(8, 'easy').verdict(), DiyVerdict.diy);
      expect(e(8, 'hard').verdict(), DiyVerdict.careful);
      expect(e(5, 'medium').verdict(), DiyVerdict.careful);
      expect(e(3, 'easy').verdict(), DiyVerdict.pro);
      expect(e(9, 'easy').verdict(diyAllowed: false), DiyVerdict.pro);
    });

    for (final c in [
      (8, 'easy', true, 'Faisable vous-même'),
      (5, 'medium', true, 'Avec prudence'),
      (2, 'hard', true, 'Appelez un pro'),
      (9, 'easy', false, 'Appelez un pro'),
    ]) {
      testWidgets('carte résultat ${c.$1}/10 ${c.$2} → « ${c.$4} » + mention sécurité', (tester) async {
        await tester.pumpWidget(host(EstimateCard(
          estimate: RepairEstimate.maybe({..._est, 'diy_feasibility': c.$1, 'difficulty': c.$2})!,
          diyAllowed: c.$3,
        )));
        expect(find.text(c.$4), findsOneWidget);
        expect(find.text('Vérifié par le moteur de sécurité Nalvium'), findsOneWidget);
        expect(find.textContaining('Estimation indicative'), findsOneWidget);
      });
    }

    testWidgets('recommandation d\'un pro : la carte de la session suit la réponse', (tester) async {
      await pumpApp(
        tester,
        location: '/session/s1',
        repo: FakeSessionsRepository(stored: sessionState(action: NextActionType.recommendProfessional, status: 'referred', estimate: _est)),
      );
      await show(tester, 'trust-badge-pro');
      expect(find.text('Appelez un pro'), findsOneWidget);
    });
  });

  // ── 4. COMPTEUR D'ÉCONOMIES ─────────────────────────────────────────
  group('économies sur l\'accueil', () {
    test('paliers', () {
      expect(savingsMilestone(49), isNull);
      expect(savingsMilestone(50), 50);
      expect(savingsMilestone(280), 250);
      expect(savingsMilestone(1200), 1000);
      expect(formatEurosInt(1000), '1 000 €');
    });

    testWidgets('hausse depuis la dernière visite : le total compte jusqu\'au nouveau, palier, mémorisé', (tester) async {
      final repo = FakeSessionsRepository(sessions: [_resolved('a', 120, 180), _resolved('b', 140, 140)]); // 141 + 131 = 272
      await pumpApp(tester, repo: repo, prefs: {'nalvium.savings_seen': 141}, settle: false);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 100));
      final mid = tester.widget<Text>(find.descendant(of: k('dash-savings-amount'), matching: find.byType(Text))).data!;
      expect(mid, isNot('272 €')); // en train de compter
      await tester.pumpAndSettle();
      expect(find.text('272 €'), findsOneWidget);
      expect(find.text('Palier atteint : 250\u00a0€ économisés'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('nalvium.savings_seen'), 272);
    });

    testWidgets('aucune hausse : chiffre affiché directement', (tester) async {
      final repo = FakeSessionsRepository(sessions: [_resolved('a', 120, 180)]);
      await pumpApp(tester, repo: repo, prefs: {'nalvium.savings_seen': 141}, settle: false);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('141 €'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('partager ses économies : carte « économies » + texte à la première personne', (tester) async {
      final share = FakeShareService();
      final repo = FakeSessionsRepository(sessions: [_resolved('a', 120, 180)]);
      await pumpApp(tester, repo: repo, share: share);
      await tapK(tester, 'dash-share-savings');
      expect(share.shared.single.text, 'J\'ai économisé 141 € sur mes dépannages avec Nalvium · nalvium.com');
      final card = share.rendered.single as SavingsShareCard;
      expect(card.amount, '141 €');
      expect(card.milestone, 'Palier atteint : 100 € économisés');
    });

    testWidgets('aucune économie : ni partage ni palier', (tester) async {
      await pumpApp(tester);
      expect(k('dash-share-savings'), findsNothing);
      expect(k('dash-milestone'), findsNothing);
    });
  });

  // ── 5. POURBOIRE AU MOMENT DE LA GRATITUDE ──────────────────────────
  group('pourboire après une réparation', () {
    Future<FakeTipsService> openResolved(WidgetTester t, {FakeTipsService? tips, Map<String, Object>? prefs, Map<String, dynamic>? estimate = _est}) async {
      final f = tips ?? FakeTipsService();
      await pumpApp(
        t,
        tips: f,
        prefs: prefs,
        location: '/session/s1',
        repo: FakeSessionsRepository(
          stored: sessionState(action: NextActionType.resolved, status: 'resolved', message: 'C\'est réglé.', estimate: estimate),
        ),
      );
      return f;
    }

    testWidgets('économie réelle : proposition douce, « pourboire », ouvre la feuille existante', (tester) async {
      await openResolved(tester);
      await show(tester, 'tip-card');
      expect(find.text('Nalvium vous a fait économiser 141\u00a0€. Un petit pourboire pour soutenir l\'app ?'), findsOneWidget);
      expect(find.textContaining('don'), findsNothing);
      expect(k('support-card'), findsNothing); // pas deux cartes de soutien
      await tapK(tester, 'tip-open');
      expect(k('support-title'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('nalvium.tip_prompt_at'), isNotNull);
    });

    testWidgets('« Plus tard » : la carte disparaît', (tester) async {
      await openResolved(tester);
      await tapK(tester, 'tip-later');
      expect(k('tip-card'), findsNothing);
      expect(k('support-card'), findsNothing);
    });

    testWidgets('déjà proposé il y a moins de 14 jours : carte habituelle seulement', (tester) async {
      final recent = DateTime.now().subtract(const Duration(days: 3)).millisecondsSinceEpoch;
      await openResolved(tester, prefs: {'nalvium.tip_prompt_at': recent});
      await show(tester, 'support-card');
      expect(k('tip-card'), findsNothing);
    });

    testWidgets('proposé il y a plus de 14 jours : de nouveau proposé', (tester) async {
      final old = DateTime.now().subtract(const Duration(days: 15)).millisecondsSinceEpoch;
      await openResolved(tester, prefs: {'nalvium.tip_prompt_at': old});
      await show(tester, 'tip-card');
    });

    testWidgets('store indisponible : aucune proposition', (tester) async {
      await openResolved(tester, tips: FakeTipsService(available: false));
      await show(tester, 'support-card');
      expect(k('tip-card'), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('nalvium.tip_prompt_at'), isNull); // rien n'est « consommé »
    });

    testWidgets('sans économie (pas d\'estimation) : aucune proposition', (tester) async {
      await openResolved(tester, estimate: null);
      expect(k('tip-card'), findsNothing);
    });

    testWidgets('arrêt de sécurité : ni pourboire ni carte de soutien', (tester) async {
      await pumpApp(
        tester,
        location: '/session/s1',
        repo: FakeSessionsRepository(stored: sessionState(action: NextActionType.safetyStop, status: 'stopped', message: 'STOP', estimate: _est)),
      );
      expect(k('tip-card'), findsNothing);
      expect(k('support-card'), findsNothing);
      expect(k('share-result'), findsNothing);
    });
  });
}
