import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/domain/diagnosis.dart';
import 'package:nalvium/services/photo_capture_service.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

const _small = Size(960, 1704); // 320×568 dp (très petit téléphone)
const _samsung = Size(720, 1600); // Samsung réel : DPR 2 → 360×800 dp
const longText =
    'Retirez délicatement le filtre au fond du lave-vaisselle, rincez-le sous l\'eau chaude puis enlevez à la main tous les débris visibles dans le puits situé juste en dessous, sans forcer.';

/// Aucun overflow ni exception de layout sur le scénario donné.
Future<void> noOverflow(WidgetTester tester, SessionStateBuilder build, {double scale = 1.0, Size size = _small}) async {
  final repo = FakeSessionsRepository(stored: build());
  await pumpApp(tester, repo: repo, location: '/session/s1', size: size, textScale: scale);
  expect(tester.takeException(), isNull);
}

typedef SessionStateBuilder = dynamic Function();

void main() {
  for (final scale in [1.0, 1.5, 2.0]) {
    group('text scale ×$scale sur petit écran', () {
      testWidgets('home avec session active', (tester) async {
        final repo = FakeSessionsRepository(sessions: [summary(title: 'Lave-vaisselle qui ne vidange plus du tout depuis ce matin', lastMessage: longText)]);
        await pumpApp(tester, repo: repo, size: _small, textScale: scale);
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(find.byKey(const Key('take-photo')), 200, scrollable: find.byType(Scrollable).first);
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('take-photo')), findsOneWidget);
      });
      testWidgets('ASK_QUESTION', (tester) async {
        await noOverflow(tester, () => sessionState(message: longText, choices: ['Oui', 'Non', 'Je ne sais pas, il faudrait que je regarde de plus près']), scale: scale);
      });
      testWidgets('INSTRUCTION avec matériel', (tester) async {
        await noOverflow(tester, () => sessionState(action: NextActionType.instruction, message: longText, items: ['Gants ménagers', 'Brosse souple', 'Un récipient']), scale: scale);
      });
      testWidgets('VERIFICATION', (tester) async {
        await noOverflow(tester, () => sessionState(action: NextActionType.verification, message: longText), scale: scale);
      });
      testWidgets('REQUEST_PHOTO', (tester) async {
        await noOverflow(tester, () => sessionState(action: NextActionType.requestPhoto, message: longText, mediaId: 'm'), scale: scale);
      });
      testWidgets('SAFETY_STOP', (tester) async {
        await noOverflow(tester, () => sessionState(action: NextActionType.safetyStop, message: 'Arrêtez-vous ici. $longText', status: 'stopped'), scale: scale);
      });
      testWidgets('RECOMMEND_PROFESSIONAL', (tester) async {
        await noOverflow(tester, () => sessionState(action: NextActionType.recommendProfessional, message: longText, status: 'referred'), scale: scale);
      });
      testWidgets('RESOLVED', (tester) async {
        await noOverflow(tester, () => sessionState(action: NextActionType.resolved, message: longText, status: 'resolved'), scale: scale);
      });
    });
  }

  testWidgets('aperçu photo : pas d\'overflow, actions visibles (petit écran, texte ×1.5)', (tester) async {
    await pumpApp(tester, captures: [CapturedPhoto(tempPhotoPath('big'))], size: _small, textScale: 1.5);
    await tester.scrollUntilVisible(find.byKey(const Key('take-photo')), 200, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('take-photo')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('use-photo')), findsOneWidget);
    expect(find.byKey(const Key('retake-photo')), findsOneWidget);
    expect(find.text('La photo est-elle assez nette ?'), findsOneWidget);
  });

  testWidgets('barre de navigation : 4 destinations + caméra, sans overflow, zones tactiles ≥ 48', (tester) async {
    await pumpApp(tester, size: _small, textScale: 2.0);
    expect(tester.takeException(), isNull);
    for (final k in ['nav-home', 'nav-house', 'nav-repair', 'nav-community']) {
      expect(tester.getSize(find.byKey(Key(k))).height, greaterThanOrEqualTo(48));
    }
    expect(tester.getSize(find.byKey(const Key('nav-camera'))).width, greaterThanOrEqualTo(56));
  });

  testWidgets('Samsung 720×1600 (360×800 dp) : Accueil sans overflow', (tester) async {
    final repo = FakeSessionsRepository(sessions: [summary(title: 'Lave-vaisselle', lastMessage: 'Vérifiez maintenant le filtre')]);
    await pumpApp(tester, size: _samsung, dpr: 2, repo: repo);
    expect(tester.takeException(), isNull);
    expect(find.text('À reprendre', skipOffstage: false), findsOneWidget);
  });

  final samsungStates = {
    'ASK_QUESTION': () => sessionState(message: longText, choices: ['Oui', 'Non', 'Je ne sais pas']),
    'INSTRUCTION': () => sessionState(action: NextActionType.instruction, message: longText, items: ['Gants', 'Brosse']),
    'VERIFICATION': () => sessionState(action: NextActionType.verification, message: 'L\'eau s\'évacue-t-elle ?'),
    'REQUEST_PHOTO': () => sessionState(action: NextActionType.requestPhoto, message: longText, mediaId: 'm'),
    'SAFETY_STOP': () => sessionState(action: NextActionType.safetyStop, message: 'Arrêtez-vous ici. $longText', status: 'stopped'),
    'RECOMMEND_PROFESSIONAL': () => sessionState(action: NextActionType.recommendProfessional, message: longText, status: 'referred'),
    'RESOLVED': () => sessionState(action: NextActionType.resolved, message: 'Réglé.', status: 'resolved', title: 'Lave-vaisselle'),
  };
  for (final e in samsungStates.entries) {
    testWidgets('Samsung 720×1600 : ${e.key} sans overflow', (tester) async {
      await pumpApp(tester, size: _samsung, dpr: 2, repo: FakeSessionsRepository(stored: e.value()), location: '/session/s1');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('sémantique : actions principales exposées comme boutons nommés', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester);
    expect(find.bySemanticsLabel(RegExp('Prendre une photo')), findsOneWidget);
    expect(find.bySemanticsLabel('Caméra'), findsOneWidget);
    expect(find.byTooltip('Historique'), findsOneWidget);
    expect(find.byTooltip('Réglages'), findsOneWidget);
    for (final label in ['Accueil', 'Maison', 'Dépannage', 'Communauté']) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    handle.dispose();
  });

  testWidgets('sémantique du guidage : titre exposé comme en-tête', (tester) async {
    final handle = tester.ensureSemantics();
    final repo = FakeSessionsRepository(stored: sessionState(action: NextActionType.instruction, message: 'Fermez le robinet.'));
    await pumpApp(tester, repo: repo, location: '/session/s1');
    expect(tester.getSemantics(find.byKey(const Key('guidance-title'))), matchesSemantics(label: 'Essayez ceci', isHeader: true, hasTapAction: false));
    handle.dispose();
  });
}
