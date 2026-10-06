import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/app.dart';
import 'package:nalvium/core/router/app_router.dart';
import 'package:nalvium/services/photo_capture_service.dart';
import 'package:nalvium/domain/video.dart';
import 'package:nalvium/services/providers.dart';
import 'package:nalvium/services/video_recorder_service.dart';

import 'fakes.dart';
import 'fake_home.dart';
import 'package:nalvium/core/ads/ads_service.dart';

class FakePhotoCaptureService implements PhotoCaptureService {
  FakePhotoCaptureService(this.results);

  /// Chaque appel consomme un résultat ; `null` = annulation, [CameraUnavailableException] = erreur.
  final List<Object?> results;
  int calls = 0;

  @override
  Future<CapturedPhoto?> takePhoto() async {
    final r = results[calls < results.length ? calls : results.length - 1];
    calls++;
    if (r is Exception) throw r;
    return r as CapturedPhoto?;
  }
}

String tempPhotoPath(String name) {
  final f = File('${Directory.systemTemp.path}/$name.png')
    ..writeAsBytesSync(const [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 0x0D, 0x49, 0x48, 0x44, 0x52, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 0x1F, 0x15, 0xC4, 0x89,
      0, 0, 0, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xFF, 0xFF, 0x3F, 0, 5, 0xFE, 2, 0xFE, 0xA7, 0x35, 0x81, 0x84, 0, 0, 0, 0, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);
  return f.path;
}

Future<FakePhotoCaptureService> pumpApp(
  WidgetTester tester, {
  List<Object?> captures = const [null],
  FakeSessionsRepository? repo,
  String location = '/home',
  Size size = const Size(1080, 3600), // pixels physiques
  double dpr = 3,
  double textScale = 1.0,
  bool reduceMotion = false,
  bool settle = true,
  FakeAdsService? ads,
  FakeVideoRecorder? recorder,
  int fileSize = 5 * 1024 * 1024,
  FakeHomeRepository? home,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = dpr;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  if (reduceMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
  }
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
  });
  final fake = FakePhotoCaptureService(captures);
  await tester.pumpWidget(ProviderScope(
    retry: (_, _) => null,
    overrides: [
      photoCaptureServiceProvider.overrideWithValue(fake),
      sessionsRepositoryProvider.overrideWithValue(repo ?? FakeSessionsRepository()),
      homeRepositoryProvider.overrideWithValue(home ?? FakeHomeRepository()),
      adsServiceProvider.overrideWithValue(ads ?? FakeAdsService()),
      videoRecorderFactoryProvider.overrideWithValue(() => recorder ?? FakeVideoRecorder()),
      videoFileSizeProvider.overrideWithValue((_) async => fileSize),
    ],
    child: NalviumApp(router: buildRouter(initialLocation: location)),
  ));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return fake;
}

/// Faux service publicitaire de TEST : enregistre les appels, aucun SDK.
class FakeAdsService implements AdsService {
  FakeAdsService({this.banner});

  /// Bannière simulée (par défaut un bloc de 60 dp) ; permet de simuler no-fill / chargement retardé.
  final Widget? banner;
  int newDiagnostics = 0;
  int suspendCalls = 0;
  int initializeCalls = 0;
  final resumes = <String>[];

  @override
  Future<void> initialize() async => initializeCalls++;

  @override
  Widget buildBanner() => banner ?? const DecoratedBox(key: Key('ad-slot'), decoration: BoxDecoration(color: Color(0xFFE3E9F2)), child: SizedBox(height: 60, width: double.infinity));

  @override
  Future<void> beforeNewDiagnostic() async => newDiagnostics++;

  @override
  Future<void> onAppResumed({required String route, required Duration backgroundFor}) async => resumes.add(route);

  @override
  Future<T> suspendAppOpen<T>(Future<T> Function() action) async {
    suspendCalls++;
    return action();
  }
}

/// Faux enregistreur vidéo de TEST : aucune caméra, comportement piloté par le test.
class FakeVideoRecorder implements VideoRecorder {
  FakeVideoRecorder({this.initError, this.audio = true, this.startError, this.path});
  final VideoException? initError;
  final VideoException? startError;
  final String? path;
  final bool audio;
  int starts = 0, stops = 0, cancels = 0, switches = 0, initializations = 0;
  bool disposed = false;

  @override
  Future<void> initialize() async {
    initializations++;
    if (initError != null) throw initError!;
  }

  @override
  bool get hasAudio => audio;
  @override
  bool get canSwitchCamera => true;
  @override
  Future<void> switchCamera() async => switches++;
  @override
  Widget buildPreview() => const ColoredBox(key: Key('camera-preview'), color: Color(0xFF223344), child: SizedBox(width: 200, height: 300));
  @override
  Future<void> start() async {
    if (startError != null) throw startError!;
    starts++;
  }

  @override
  Future<String> stop() async {
    stops++;
    return path ?? tempPhotoPath('video_fake');
  }

  @override
  Future<void> cancel() async => cancels++;
  @override
  Future<void> dispose() async => disposed = true;
}
