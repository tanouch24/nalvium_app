import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/services/photo_capture_service.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

Future<FakeSessionsRepository> openAnalysis(
  WidgetTester tester, {
  Size size = const Size(720, 1600),
  double dpr = 2,
  double scale = 1.0,
  bool reduceMotion = false,
}) async {
  final repo = FakeSessionsRepository(turns: [sessionState()])..turnGate = Completer<void>();
  await pumpApp(
    tester,
    repo: repo,
    captures: [CapturedPhoto(tempPhotoPath('x'))],
    size: size,
    dpr: dpr,
    textScale: scale,
    reduceMotion: reduceMotion,
  );
  await tester.scrollUntilVisible(find.byKey(const Key('take-photo')), 100, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(find.byKey(const Key('take-photo')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('take-photo')));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const Key('use-photo')));
  await tester.pump();
  await tester.tap(find.byKey(const Key('use-photo')));
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 600));
  return repo;
}

void main() {
  for (final cfg in [
    ('Samsung 360×800', const Size(720, 1600), 2.0),
    ('petit écran 320×568', const Size(960, 1704), 3.0),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('ANALYSE ${cfg.$1} · ×$scale : aucun overflow, titre et Annuler accessibles, photo visible', (tester) async {
        final repo = await openAnalysis(tester, size: cfg.$2, dpr: cfg.$3, scale: scale);
        expect(tester.takeException(), isNull);
        expect(find.text('J\'analyse le problème…'), findsOneWidget);
        expect(find.text('Je regarde ce qui pourrait provoquer ça.'), findsOneWidget);
        final cancel = find.byKey(const Key('cancel-analysis'));
        await tester.ensureVisible(cancel);
        await tester.pump();
        expect(tester.getSize(cancel).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(cancel).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(find.byType(Image).first).height, greaterThan(100)); // la photo reste lisible
        repo.turnGate!.complete();
        await tester.pumpAndSettle();
      });
    }
  }

  testWidgets('ANALYSE : « Annuler » ne bouge pas quand la phrase change', (tester) async {
    final repo = await openAnalysis(tester);
    final before = tester.getTopLeft(find.byKey(const Key('cancel-analysis')));
    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('J\'observe les éléments visibles.'), findsOneWidget);
    expect(tester.getTopLeft(find.byKey(const Key('cancel-analysis'))), before);
    repo.turnGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('ANALYSE : barre d\'état à icônes sombres (fond clair)', (tester) async {
    final repo = await openAnalysis(tester);
    final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.ancestor(of: find.byType(Scaffold).first, matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>)).first,
    );
    expect(region.value.statusBarIconBrightness, Brightness.dark);
    repo.turnGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('ANALYSE : réduire les animations → coins immobiles, rien ne boucle', (tester) async {
    final repo = await openAnalysis(tester, reduceMotion: true);
    final a = tester.getRect(find.byType(CustomPaint).last);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.getRect(find.byType(CustomPaint).last), a);
    expect(tester.takeException(), isNull);
    repo.turnGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('ANALYSE : le comportement ne change pas : la vraie réponse ouvre la question', (tester) async {
    final repo = await openAnalysis(tester);
    repo.turnGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Question ?'), findsOneWidget);
  });
}
