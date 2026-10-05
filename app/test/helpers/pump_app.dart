import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/app.dart';
import 'package:nalvium/core/router/app_router.dart';
import 'package:nalvium/services/photo_capture_service.dart';
import 'package:nalvium/services/providers.dart';

import 'fakes.dart';

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
}) async {
  tester.view.physicalSize = const Size(1080, 2800);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final fake = FakePhotoCaptureService(captures);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      photoCaptureServiceProvider.overrideWithValue(fake),
      sessionsRepositoryProvider.overrideWithValue(repo ?? FakeSessionsRepository()),
    ],
    child: NalviumApp(router: buildRouter(initialLocation: location)),
  ));
  await tester.pumpAndSettle();
  return fake;
}
