import 'dart:async';

import 'package:nalvium/core/network/api_exceptions.dart';
import 'package:nalvium/data/sessions_repository.dart';
import 'package:nalvium/domain/diagnosis.dart';
import 'package:nalvium/domain/session.dart';

SessionState sessionState({
  String id = 's1',
  NextActionType action = NextActionType.askQuestion,
  String message = 'Question ?',
  List<String> choices = const [],
  List<String> items = const [],
  int? step,
  String status = 'active',
  bool pending = false,
  String? title = 'Fuite sous l\'évier',
  String? mediaId,
  int messages = 2,
  String? category = 'plumbing',
  List<String> observations = const [],
  List<Map<String, dynamic>> actions = const [],
}) {
  final wire = switch (action) {
    NextActionType.askQuestion => 'ASK_QUESTION',
    NextActionType.requestPhoto => 'REQUEST_PHOTO',
    NextActionType.instruction => 'INSTRUCTION',
    NextActionType.verification => 'VERIFICATION',
    NextActionType.safetyStop => 'SAFETY_STOP',
    NextActionType.recommendProfessional => 'RECOMMEND_PROFESSIONAL',
    NextActionType.resolved => 'RESOLVED',
  };
  return SessionState.fromJson({
    'id': id,
    'status': status,
    'current_state': wire,
    'title': title,
    'category': category,
    'updated_at': '2026-10-05T13:45:00+00:00',
    'actions': actions,
    'risk_level': 'low',
    'pending_analysis': pending,
    'latest_media_id': mediaId,
    'messages': List.generate(messages, (_) => {}),
    'next': {
      'action_type': wire,
      'message': message,
      'choices': choices,
      'required_items': items,
      'observations': observations,
      'step_number': step,
      'diy_allowed': true,
    },
  });
}

SessionSummary summary({
  String id = 's1',
  String state = 'ASK_QUESTION',
  String status = 'active',
  String? title = 'Fuite sous l\'évier',
  String? lastMessage,
  String? category = 'plumbing',
  DateTime? updatedAt,
}) =>
    SessionSummary(id: id, status: status, currentState: state, title: title, category: category, updatedAt: updatedAt ?? DateTime.now(), firstMediaId: null, lastMessage: lastMessage);

/// Faux dépôt de TEST : renvoie des résultats prévus par le test (jamais utilisé dans l'app).
class FakeSessionsRepository implements SessionsRepository {
  FakeSessionsRepository({List<Object> turns = const [], this.sessions = const [], this.stored})
      : turns = List<Object>.of(turns);

  /// Chaque appel à sendTurn consomme un résultat : SessionState ou ApiException.
  final List<Object> turns;
  List<SessionSummary> sessions;
  SessionState? stored; // ce que getSession renvoie (état « serveur »)
  final calls = <String>[];
  final inputs = <TurnInput?>[];
  Object? listError;
  Object? getError;

  /// Si défini, sendTurn attend ce Completer (permet d'observer l'écran d'attente).
  Completer<void>? turnGate;

  @override
  Future<String> createSession() async {
    calls.add('create');
    return 's1';
  }

  @override
  Future<String> uploadPhoto(String sessionId, String filePath) async {
    calls.add('upload');
    return 'm${calls.where((c) => c == 'upload').length}';
  }

  @override
  Future<String> uploadVideo(String sessionId, String filePath) async {
    calls.add('upload_video');
    return 'v${calls.where((c) => c == 'upload_video').length}';
  }

  @override
  Future<SessionState> sendTurn(String sessionId, TurnInput? input) async {
    calls.add('turn');
    inputs.add(input);
    if (turnGate != null) await turnGate!.future;
    final r = turns.removeAt(0);
    if (r is ApiException) throw r;
    stored = r as SessionState;
    return stored!;
  }

  @override
  Future<SessionState> getSession(String sessionId) async {
    calls.add('get');
    if (getError case final ApiException e) throw e;
    return stored ?? (throw const ApiNetworkException());
  }

  @override
  Future<List<SessionSummary>> listSessions({bool activeOnly = false}) async {
    calls.add('list');
    if (listError case final ApiException e) throw e;
    return activeOnly ? sessions.where((s) => s.status == 'active').toList() : sessions;
  }
}
