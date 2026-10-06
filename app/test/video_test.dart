import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/core/ads/ad_policy.dart';
import 'package:nalvium/core/network/api_exceptions.dart';
import 'package:nalvium/domain/diagnosis.dart';
import 'package:nalvium/domain/session.dart';
import 'package:nalvium/domain/video.dart';
import 'package:nalvium/services/photo_capture_service.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

Future<void> openCapture(WidgetTester tester, {FakeVideoRecorder? recorder, FakeSessionsRepository? repo, FakeAdsService? ads, int fileSize = 5 * 1024 * 1024, List<Object?> captures = const [null]}) async {
  await pumpApp(tester, recorder: recorder, repo: repo, ads: ads, fileSize: fileSize, captures: captures);
  await tester.tap(find.byKey(const Key('film-problem')));
  await tester.pumpAndSettle();
}

Future<void> record(WidgetTester tester, Duration length) async {
  await tester.tap(find.byKey(const Key('record-button')));
  await tester.pump();
  await tester.pump(length);
}

Future<void> stopRecording(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('record-button')));
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  group('HOME / FILMER', () {
    testWidgets('« Bientôt » est supprimé et Filmer est actif', (tester) async {
      await pumpApp(tester);
      expect(find.text('Bientôt'), findsNothing);
      expect(find.text('Bientôt disponible'), findsNothing);
      expect(find.text('Filmer'), findsOneWidget);
      expect(find.text('Décrire'), findsOneWidget);
      await tester.tap(find.byKey(const Key('film-problem')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('camera-preview')), findsOneWidget); // vraie capture, pas un message
    });

    testWidgets('la photo reste l\'action principale (plus grande que Décrire et Filmer)', (tester) async {
      await pumpApp(tester);
      final photo = tester.getSize(find.byKey(const Key('take-photo')));
      expect(photo.height, greaterThan(tester.getSize(find.byKey(const Key('film-problem'))).height * 2.5));
    });
  });

  group('CAPTURE', () {
    testWidgets('limite affichée, temps restant réel qui décroît, arrêt manuel', (tester) async {
      final rec = FakeVideoRecorder();
      await openCapture(tester, recorder: rec);
      expect(find.text('15 secondes maximum'), findsOneWidget);
      await record(tester, const Duration(seconds: 3));
      expect(rec.starts, 1);
      expect(find.text('12 s restantes'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('8 s restantes'), findsOneWidget);
      await stopRecording(tester);
      expect(rec.stops, 1);
      expect(find.byKey(const Key('use-video')), findsOneWidget); // aperçu
      expect(find.text('0:07'), findsOneWidget); // durée réelle (≈ 7 s), pas 15
    });

    testWidgets('arrêt automatique à 15 s, jamais plus', (tester) async {
      final rec = FakeVideoRecorder();
      await openCapture(tester, recorder: rec);
      await record(tester, const Duration(milliseconds: 14800));
      expect(rec.stops, 0);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(rec.stops, 1);
      expect(find.byKey(const Key('use-video')), findsOneWidget);
      expect(find.text('0:15'), findsOneWidget);
    });

    testWidgets('annuler pendant l\'enregistrement : rien n\'est gardé, retour à l\'accueil', (tester) async {
      final rec = FakeVideoRecorder();
      await openCapture(tester, recorder: rec);
      await record(tester, const Duration(seconds: 2));
      await tester.tap(find.byKey(const Key('video-close')));
      await tester.pumpAndSettle();
      expect(rec.cancels, greaterThanOrEqualTo(1));
      expect(rec.stops, 0);
      expect(find.text('Un problème à la maison ?'), findsOneWidget);
      expect(find.byKey(const Key('use-video')), findsNothing);
    });

    testWidgets('vidéo vide / trop courte : message clair, pas d\'aperçu', (tester) async {
      await openCapture(tester);
      await record(tester, const Duration(milliseconds: 300));
      await stopRecording(tester);
      expect(find.text('Vidéo trop courte'), findsOneWidget);
      expect(find.byKey(const Key('use-video')), findsNothing);
      expect(find.byKey(const Key('retry')), findsOneWidget);
      expect(find.byKey(const Key('alt-photo')), findsOneWidget);
      expect(find.byKey(const Key('alt-describe')), findsOneWidget);
    });

    testWidgets('fichier trop gros : refusé avant tout envoi', (tester) async {
      final repo = FakeSessionsRepository();
      await openCapture(tester, repo: repo, fileSize: kMaxVideoBytes + 1);
      await record(tester, const Duration(seconds: 3));
      await stopRecording(tester);
      expect(find.text('Cette vidéo est trop lourde'), findsOneWidget);
      expect(repo.calls.where((c) => c.startsWith('upload')), isEmpty);
    });

    testWidgets('permission caméra refusée : explication + sorties (réessayer / photo / décrire)', (tester) async {
      final rec = FakeVideoRecorder(initError: const VideoException(VideoFailure.cameraDenied));
      await openCapture(tester, recorder: rec);
      expect(find.text('L\'accès à la caméra est nécessaire'), findsOneWidget);
      expect(find.byKey(const Key('retry')), findsOneWidget);
      expect(find.byKey(const Key('alt-photo')), findsOneWidget);
      expect(find.byKey(const Key('alt-describe')), findsOneWidget);
      await tester.tap(find.byKey(const Key('retry')));
      await tester.pumpAndSettle();
      expect(rec.initializations, 2); // on peut réessayer sans plantage
    });

    testWidgets('caméra indisponible', (tester) async {
      await openCapture(tester, recorder: FakeVideoRecorder(initError: const VideoException(VideoFailure.cameraUnavailable)));
      expect(find.text('La caméra n\'est pas disponible'), findsOneWidget);
    });

    testWidgets('« Décrire » depuis l\'erreur ouvre la description', (tester) async {
      await openCapture(tester, recorder: FakeVideoRecorder(initError: const VideoException(VideoFailure.cameraDenied)));
      await tester.tap(find.byKey(const Key('alt-describe')));
      await tester.pumpAndSettle();
      expect(find.text('Que se passe-t-il ?'), findsOneWidget);
    });

    testWidgets('micro refusé, caméra autorisée : le flux continue SANS son et le dit', (tester) async {
      await openCapture(tester, recorder: FakeVideoRecorder(audio: false));
      expect(find.byKey(const Key('video-no-sound')), findsOneWidget);
      await record(tester, const Duration(seconds: 3));
      await stopRecording(tester);
      expect(find.byKey(const Key('video-no-audio-note')), findsOneWidget);
      expect(find.text('Cette vidéo n\'a pas de son.'), findsOneWidget);
    });

    testWidgets('avec son : aucune mention « sans son »', (tester) async {
      await openCapture(tester);
      expect(find.byKey(const Key('video-no-sound')), findsNothing);
    });

    testWidgets('changer de caméra possible hors enregistrement uniquement', (tester) async {
      final rec = FakeVideoRecorder();
      await openCapture(tester, recorder: rec);
      await tester.tap(find.byKey(const Key('video-switch')));
      await tester.pump();
      expect(rec.switches, 1);
      await record(tester, const Duration(seconds: 1));
      expect(find.byKey(const Key('video-switch')), findsNothing);
      await stopRecording(tester);
    });

    testWidgets('échec du démarrage de l\'enregistrement : erreur gérée', (tester) async {
      await openCapture(tester, recorder: FakeVideoRecorder(startError: const VideoException(VideoFailure.cameraUnavailable)));
      await tester.tap(find.byKey(const Key('record-button')));
      await tester.pumpAndSettle();
      expect(find.text('La caméra n\'est pas disponible'), findsOneWidget);
    });

    testWidgets('aucune permission n\'est demandée au lancement : seule l\'ouverture de « Filmer » initialise la caméra', (tester) async {
      final rec = FakeVideoRecorder();
      await pumpApp(tester, recorder: rec);
      expect(rec.initializations, 0);
      await tester.tap(find.byKey(const Key('film-problem')));
      await tester.pumpAndSettle();
      expect(rec.initializations, 1);
    });
  });

  group('APERÇU', () {
    testWidgets('durée, utilisation et refilmer ; aucun montage / filtre', (tester) async {
      final rec = FakeVideoRecorder();
      await openCapture(tester, recorder: rec);
      await record(tester, const Duration(seconds: 5));
      await stopRecording(tester);
      expect(find.byKey(const Key('video-duration')), findsOneWidget);
      expect(find.text('Utiliser cette vidéo'), findsOneWidget);
      expect(find.text('Refilmer'), findsOneWidget);
      expect(find.text('La vidéo est-elle assez claire ?'), findsOneWidget);
      for (final word in ['Filtre', 'Montage', 'Couper', 'Trim']) {
        expect(find.textContaining(word), findsNothing);
      }
      // lecture impossible dans l'environnement de test : message honnête, on peut quand même continuer
      expect(find.byKey(const Key('video-cannot-play')), findsOneWidget);
      await tester.tap(find.byKey(const Key('refilm-video')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('record-button')), findsOneWidget); // retour à la capture
      expect(rec.initializations, 2);
    });

    testWidgets('« Utiliser cette vidéo » : upload privé, tour « video », même écran guidé', (tester) async {
      final repo = FakeSessionsRepository(turns: [sessionState(message: 'Le bruit est-il régulier ?', choices: ['Oui', 'Non'])]);
      final ads = FakeAdsService();
      await openCapture(tester, repo: repo, ads: ads);
      await record(tester, const Duration(seconds: 6));
      await stopRecording(tester);
      await tester.tap(find.byKey(const Key('use-video')));
      await tester.pumpAndSettle();
      expect(repo.calls, containsAllInOrder(['create', 'upload_video', 'turn']));
      expect(repo.inputs.single, isA<VideoTurn>());
      expect((repo.inputs.single! as VideoTurn).toJson(), {'kind': 'video', 'media_id': 'v1'});
      expect(ads.newDiagnostics, 1);
      expect(find.text('J\'ai besoin de vérifier un point'), findsOneWidget); // mêmes écrans / action_type que photo et texte
    });
  });

  group('APERÇU — mise en page', () {
    for (final cfg in [('Samsung 360×800', const Size(720, 1600), 2.0, 1.0), ('petit écran 320×568', const Size(960, 1704), 3.0, 1.0), ('Samsung, texte ×1,5', const Size(720, 1600), 2.0, 1.5)]) {
      testWidgets('les deux actions restent visibles et atteignables : ${cfg.$1}', (tester) async {
        await pumpApp(tester, size: cfg.$2, dpr: cfg.$3, textScale: cfg.$4, recorder: FakeVideoRecorder());
        await tester.scrollUntilVisible(find.byKey(const Key('film-problem')), 200, scrollable: find.byType(Scrollable).first);
        await tester.ensureVisible(find.byKey(const Key('film-problem'))); // entièrement visible, pas seulement effleuré par le bord
        await tester.pump();
        await tester.tap(find.byKey(const Key('film-problem')));
        await tester.pumpAndSettle();
        await record(tester, const Duration(seconds: 4));
        await stopRecording(tester);
        final screen = tester.view.physicalSize.height / tester.view.devicePixelRatio;
        await tester.ensureVisible(find.byKey(const Key('use-video')));
        await tester.pump();
        expect(tester.getRect(find.byKey(const Key('use-video'))).bottom, lessThanOrEqualTo(screen));
        expect(tester.takeException(), isNull);
        // à taille de texte normale, « Refilmer » est visible SANS défiler
        if (cfg.$4 == 1.0) {
          expect(tester.getRect(find.byKey(const Key('refilm-video'))).bottom, lessThanOrEqualTo(screen));
        }
      });
    }
  });

  group('ANALYSE vidéo', () {
    testWidgets('variante vidéo : titre, phrase d\'attente, aucune promesse d\'écoute, pas de faux progrès', (tester) async {
      final repo = FakeSessionsRepository(turns: [sessionState()])..turnGate = Completer<void>();
      await openCapture(tester, repo: repo);
      await record(tester, const Duration(seconds: 4));
      await stopRecording(tester);
      await tester.tap(find.byKey(const Key('use-video')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('J\'analyse votre vidéo…'), findsOneWidget);
      expect(find.text('J\'observe ce qui change dans la vidéo.'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      for (final lie in ['écoute', 'entend', 'bruit détecté', 'son analysé']) {
        expect(find.textContaining(lie), findsNothing, reason: lie);
      }
      repo.turnGate!.complete();
      await tester.pumpAndSettle();
    });

    for (final c in [
      (ApiHttpException(422, 'video_too_long'), 'Cette vidéo est trop longue'),
      (ApiHttpException(413, 'file_too_large'), 'Cette vidéo est trop lourde'),
      (ApiHttpException(422, 'invalid_video'), 'Format de vidéo non pris en charge'),
    ]) {
      testWidgets('erreur serveur ${c.$1.code} : message dédié + sorties photo / décrire', (tester) async {
        final repo = _UploadFails(c.$1);
        await openCapture(tester, repo: repo);
        await record(tester, const Duration(seconds: 4));
        await stopRecording(tester);
        await tester.tap(find.byKey(const Key('use-video')));
        await tester.pumpAndSettle();
        expect(find.text(c.$2), findsOneWidget);
        expect(find.byKey(const Key('alt-photo')), findsOneWidget);
        expect(find.byKey(const Key('alt-describe')), findsOneWidget);
        expect(find.byKey(const Key('retry')), findsOneWidget);
      });
    }

    testWidgets('upload interrompu (réseau) : Réessayer reprend sans recréer la session', (tester) async {
      final repo = _UploadFails(const ApiNetworkException(), failTimes: 1, turns: [sessionState()]);
      await openCapture(tester, repo: repo);
      await record(tester, const Duration(seconds: 4));
      await stopRecording(tester);
      await tester.tap(find.byKey(const Key('use-video')));
      await tester.pumpAndSettle();
      expect(find.text('Impossible de joindre Nalvium'), findsOneWidget);
      await tester.tap(find.byKey(const Key('retry')));
      await tester.pumpAndSettle();
      expect(repo.calls.where((c) => c == 'create').length, 1);
      expect(repo.calls.where((c) => c == 'upload_video').length, 2);
      expect(find.text('Question ?'), findsOneWidget);
    });

    testWidgets('IA indisponible (503) : état honnête et sorties', (tester) async {
      final repo = FakeSessionsRepository(turns: [const ApiHttpException(503, 'analysis_unavailable')]);
      await openCapture(tester, repo: repo);
      await record(tester, const Duration(seconds: 4));
      await stopRecording(tester);
      await tester.tap(find.byKey(const Key('use-video')));
      await tester.pumpAndSettle();
      expect(find.text('L\'analyse n\'est pas disponible pour le moment'), findsOneWidget);
      expect(find.byKey(const Key('alt-photo')), findsOneWidget);
    });
  });

  group('SESSION vidéo', () {
    testWidgets('reprise : vignette = image de la vidéo avec badge lecture', (tester) async {
      final json = {
        'id': 's1', 'status': 'active', 'current_state': 'ASK_QUESTION', 'title': 'Bruit de pompe', 'category': 'appliance',
        'pending_analysis': false, 'latest_media_id': 'm9', 'messages': [{}, {}],
        'media': [{'id': 'm9', 'media_type': 'video', 'duration_s': 9.0, 'has_audio': true}],
        'next': {'action_type': 'ASK_QUESTION', 'message': 'Le bruit est-il régulier ?', 'choices': ['Oui', 'Non'], 'required_items': [], 'observations': []},
      };
      final state = SessionState.fromJson(json);
      expect(state.latestMediaIsVideo, isTrue);
      final repo = FakeSessionsRepository(stored: state);
      await pumpApp(tester, repo: repo, location: '/session/s1');
      expect(find.byKey(const Key('video-badge')), findsOneWidget);
      expect(find.text('Le bruit est-il régulier ?'), findsOneWidget);
    });

    testWidgets('REQUEST_PHOTO au milieu d\'un diagnostic vidéo : « Votre vidéo → À prendre », aucune pub', (tester) async {
      final ads = FakeAdsService();
      final json = {
        'id': 's1', 'status': 'active', 'current_state': 'REQUEST_PHOTO', 'title': 'Fuite', 'category': 'plumbing',
        'pending_analysis': false, 'latest_media_id': 'm9', 'messages': [{}, {}],
        'media': [{'id': 'm9', 'media_type': 'video'}],
        'next': {'action_type': 'REQUEST_PHOTO', 'message': 'Photographiez le raccord.', 'choices': [], 'required_items': [], 'observations': []},
      };
      final repo = FakeSessionsRepository(stored: SessionState.fromJson(json), turns: [sessionState(action: NextActionType.instruction, message: 'Resserrez.')]);
      await pumpApp(tester, repo: repo, ads: ads, location: '/session/s1', captures: [CapturedPhoto(tempPhotoPath('mid'))]);
      expect(find.text('Votre vidéo'), findsOneWidget);
      await tester.tap(find.byKey(const Key('take-requested-photo')));
      await tester.pumpAndSettle();
      expect(repo.calls, containsAllInOrder(['upload', 'turn']));
      expect(ads.newDiagnostics, 0); // même session : aucune pub
    });

    testWidgets('SAFETY_STOP après une vidéo : aucun bouton DIY', (tester) async {
      final repo = FakeSessionsRepository(turns: [sessionState(action: NextActionType.safetyStop, message: 'Arrêtez-vous ici. Fumée : sortez.', status: 'stopped')]);
      await openCapture(tester, repo: repo);
      await record(tester, const Duration(seconds: 4));
      await stopRecording(tester);
      await tester.tap(find.byKey(const Key('use-video')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('safety-title')), findsOneWidget);
      for (final k in ['action-done', 'take-requested-photo', 'send-answer']) {
        expect(find.byKey(Key(k)), findsNothing);
      }
    });
  });

  group('ADMOB — compteur GLOBAL de nouveaux diagnostics', () {
    testWidgets('#1 photo sans pub, #2 vidéo avec pub, #3 texte avec pub', (tester) async {
      final ads = _PolicyAds();
      final repo = FakeSessionsRepository(turns: [sessionState(), sessionState(), sessionState()]);
      await pumpApp(tester, repo: repo, ads: ads, captures: [CapturedPhoto(tempPhotoPath('g1'))]);

      // #1 : photo
      await tester.tap(find.byKey(const Key('take-photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('use-photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('close-session')));
      await tester.pumpAndSettle();
      // #2 : vidéo
      await tester.tap(find.byKey(const Key('film-problem')));
      await tester.pumpAndSettle();
      await record(tester, const Duration(seconds: 4));
      await stopRecording(tester);
      await tester.tap(find.byKey(const Key('use-video')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('close-session')));
      await tester.pumpAndSettle();
      // #3 : texte
      await tester.tap(find.byKey(const Key('describe-problem')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('describe-field')), 'Mon robinet goutte');
      await tester.pump();
      await tester.tap(find.byKey(const Key('describe-continue')));
      await tester.pumpAndSettle();

      expect(ads.interstitialShown, [false, true, true]); // UN compteur global, pas « un gratuit par type »
    });

    test('aucune pub plein écran sur les écrans vidéo (capture, aperçu)', () {
      expect(AdPolicy.isInsideSession('/video/capture'), isTrue);
      expect(AdPolicy.isInsideSession('/video/preview'), isTrue);
      final p = AdPolicy(counter: _MemCounter());
      expect(p.appOpenAllowed(route: '/video/capture', backgroundFor: const Duration(hours: 1)), isFalse);
    });
  });

  test('modèles : VideoTurn et durée', () {
    expect(const VideoTurn('m1').toJson(), {'kind': 'video', 'media_id': 'm1'});
    expect(formatClock(const Duration(seconds: 7)), '0:07');
    expect(formatClock(const Duration(seconds: 75)), '1:15');
    expect(kMaxVideoSeconds, 15);
  });
}

class _MemCounter implements DiagnosticCounter {
  int n = 0;
  @override
  Future<int> count() async => n;
  @override
  Future<void> increment() async => n++;
}

/// Vraie politique + faux affichage : enregistre si un interstitiel aurait été montré à chaque nouveau diagnostic.
class _PolicyAds extends FakeAdsService {
  final policy = AdPolicy(counter: _MemCounter(), cooldown: Duration.zero);
  final interstitialShown = <bool>[];

  @override
  Future<void> beforeNewDiagnostic() async {
    final due = await policy.interstitialDueForNewDiagnostic();
    await policy.recordDiagnosticStarted();
    interstitialShown.add(due);
  }
}

/// Dépôt dont l'upload vidéo échoue (n fois), pour tester les erreurs.
class _UploadFails extends FakeSessionsRepository {
  // ignore: use_super_parameters
  _UploadFails(this.error, {this.failTimes = 1 << 30, List<Object> turns = const []}) : super(turns: turns);
  final Object error;
  int failTimes;

  @override
  Future<String> uploadVideo(String sessionId, String filePath) async {
    calls.add('upload_video');
    if (failTimes > 0) {
      failTimes--;
      throw error;
    }
    return 'v1';
  }
}
