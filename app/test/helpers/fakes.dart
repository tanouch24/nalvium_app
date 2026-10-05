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
    'category': 'plumbing',
    'risk_level': 'low',
    'pending_analysis': pending,
    'latest_media_id': mediaId,
    'messages': List.generate(messages, (_) => {}),
    'next': {
      'action_type': wire,
      'message': message,
      'choices': choices,
      'required_items': items,
      'step_number': step,
      'diy_allowed': true,
    },
  });
}

SessionSummary summary({String id = 's1', String state = 'ASK_QUESTION', String status = 'active', String? title = 'Fuite sous l\'évier'}) =>
    SessionSummary(id: id, status: status, currentState: state, title: title, updatedAt: DateTime(2026, 10, 5), firstMediaId: null);

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
  Future<SessionState> sendTurn(String sessionId, TurnInput? input) async {
    calls.add('turn');
    inputs.add(input);
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
