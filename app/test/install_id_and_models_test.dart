import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/domain/diagnosis.dart';
import 'package:nalvium/domain/session.dart';
import 'package:nalvium/features/session/views/action_views.dart';
import 'package:nalvium/services/install_id_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('identité anonyme par installation', () {
    test('premier lancement : UUID aléatoire valide, stocké', () async {
      SharedPreferences.setMockInitialValues({});
      final id = await InstallIdStore().getOrCreate();
      expect(Uuid.isValidUUID(fromString: id), isTrue);
      expect((await SharedPreferences.getInstance()).getString(InstallIdStore.key), id);
    });

    test('persistant : un nouveau store (redémarrage) retrouve le même identifiant', () async {
      SharedPreferences.setMockInitialValues({});
      final first = await InstallIdStore().getOrCreate();
      final second = await InstallIdStore().getOrCreate();
      expect(second, first);
    });

    test('deux installations ont des identifiants différents', () async {
      SharedPreferences.setMockInitialValues({});
      final a = await InstallIdStore().getOrCreate();
      SharedPreferences.setMockInitialValues({});
      final b = await InstallIdStore().getOrCreate();
      expect(a, isNot(b));
    });

    test('valeur corrompue : régénérée', () async {
      SharedPreferences.setMockInitialValues({InstallIdStore.key: 'n-importe-quoi'});
      expect(Uuid.isValidUUID(fromString: await InstallIdStore().getOrCreate()), isTrue);
    });
  });

  group('modèles de session', () {
    test('SessionState.fromJson', () {
      final s = SessionState.fromJson({
        'id': 's1',
        'status': 'active',
        'current_state': 'INSTRUCTION',
        'title': 'Fuite',
        'category': 'plumbing',
        'risk_level': 'low',
        'pending_analysis': false,
        'latest_media_id': 'm1',
        'messages': [{}, {}],
        'next': {'action_type': 'INSTRUCTION', 'message': 'Fermez', 'choices': [], 'required_items': ['clé'], 'step_number': 2, 'diy_allowed': true},
      });
      expect(s.isActive, isTrue);
      expect(s.messageCount, 2);
      expect(s.next!.actionType, NextActionType.instruction);
      expect(s.next!.stepNumber, 2);
      expect(s.next!.requiredItems, ['clé']);
    });

    test('tours envoyés au backend', () {
      expect(const DescriptionTurn('a').toJson(), {'kind': 'description', 'text': 'a'});
      expect(const AnswerTurn('Oui').toJson(), {'kind': 'answer', 'text': 'Oui'});
      expect(const PhotoTurn('m1').toJson(), {'kind': 'photo', 'media_id': 'm1'});
      expect(const ActionResultTurn(ActionChoice.cannot).toJson(), {'kind': 'action_result', 'choice': 'cannot'});
    });

    test('stripStopPrefix', () {
      expect(stripStopPrefix('Arrêtez-vous ici. Sortez.'), 'Sortez.');
      expect(stripStopPrefix('arrêtez-vous ici.  Sortez.'), 'Sortez.');
      expect(stripStopPrefix('Sortez tout de suite.'), 'Sortez tout de suite.');
    });
  });
}
