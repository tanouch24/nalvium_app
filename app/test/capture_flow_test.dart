import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/domain/session.dart';
import 'package:nalvium/services/photo_capture_service.dart';

import 'helpers/fakes.dart';
import 'helpers/pump_app.dart';

void main() {
  testWidgets('photo → aperçu → Utiliser cette photo → vraie analyse → écran guidé', (tester) async {
    final repo = FakeSessionsRepository(turns: [
      sessionState(message: 'Je vois de l\'eau sous l\'évier. D\'où vient-elle ?', choices: ['Oui', 'Non']),
    ]);
    final fake = await pumpApp(tester, captures: [CapturedPhoto(tempPhotoPath('a'))], repo: repo);

    await tester.tap(find.byKey(const Key('take-photo')));
    await tester.pumpAndSettle();
    expect(fake.calls, 1);
    expect(find.byKey(const Key('preview-image')), findsOneWidget);
    expect(find.text('Reprendre'), findsOneWidget);

    await tester.tap(find.byKey(const Key('use-photo')));
    await tester.pumpAndSettle();
    expect(repo.calls, containsAllInOrder(['create', 'upload', 'turn']));
    expect(repo.inputs.single, isA<PhotoTurn>());
    expect(find.textContaining('Je vois de l\'eau sous l\'évier'), findsOneWidget);
    expect(find.text('L\'analyse n\'est pas encore disponible'), findsNothing);
  });

  testWidgets('Reprendre rouvre la caméra et remplace la photo', (tester) async {
    final fake = await pumpApp(tester, captures: [CapturedPhoto(tempPhotoPath('a')), CapturedPhoto(tempPhotoPath('b'))]);

    await tester.tap(find.byKey(const Key('nav-camera')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('retake-photo')));
    await tester.pumpAndSettle();

    expect(fake.calls, 2);
    final image = tester.widget<Image>(find.byKey(const Key('preview-image')));
    expect((image.image as FileImage).file.path, endsWith('b.png'));
  });

  testWidgets('Reprendre puis annuler garde la photo actuelle', (tester) async {
    await pumpApp(tester, captures: [CapturedPhoto(tempPhotoPath('a')), null]);
    await tester.tap(find.byKey(const Key('nav-camera')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('retake-photo')));
    await tester.pumpAndSettle();
    final image = tester.widget<Image>(find.byKey(const Key('preview-image')));
    expect((image.image as FileImage).file.path, endsWith('a.png'));
  });

  testWidgets('caméra indisponible : message clair, pas de plantage', (tester) async {
    await pumpApp(tester, captures: [const CameraUnavailableException()]);
    await tester.tap(find.byKey(const Key('take-photo')));
    await tester.pump();
    expect(find.textContaining('Impossible d\'ouvrir la caméra'), findsOneWidget);
    expect(find.text('Un problème à la maison ?'), findsOneWidget);
  });
}
