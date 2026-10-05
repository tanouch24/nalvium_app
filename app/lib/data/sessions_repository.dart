import '../core/network/api_client.dart';
import '../core/network/api_exceptions.dart';
import '../domain/session.dart';

/// Accès aux sessions du backend (source de vérité).
abstract interface class SessionsRepository {
  Future<String> createSession();
  Future<String> uploadPhoto(String sessionId, String filePath);

  /// [input] null = relancer l'analyse d'un message utilisateur resté sans réponse.
  Future<SessionState> sendTurn(String sessionId, TurnInput? input);
  Future<SessionState> getSession(String sessionId);
  Future<List<SessionSummary>> listSessions({bool activeOnly = false});
}

class HttpSessionsRepository implements SessionsRepository {
  HttpSessionsRepository(this._api);
  final ApiClient _api;

  @override
  Future<String> createSession() async {
    final json = await _api.postJson('/v1/sessions');
    return _map(json)['id'] as String;
  }

  @override
  Future<String> uploadPhoto(String sessionId, String filePath) async {
    final json = await _api.postFile('/v1/sessions/$sessionId/media', field: 'file', filePath: filePath);
    return _map(json)['id'] as String;
  }

  @override
  Future<SessionState> sendTurn(String sessionId, TurnInput? input) async {
    final json = await _api.postJson('/v1/sessions/$sessionId/turn', body: input?.toJson(), analysis: true);
    return _parse(() => SessionState.fromJson(_map(json)));
  }

  @override
  Future<SessionState> getSession(String sessionId) async {
    final json = await _api.getJson('/v1/sessions/$sessionId');
    return _parse(() => SessionState.fromJson(_map(json)));
  }

  @override
  Future<List<SessionSummary>> listSessions({bool activeOnly = false}) async {
    final json = await _api.getJson('/v1/sessions', query: {'active': '$activeOnly'});
    if (json is! List) throw const ApiProtocolException();
    return _parse(() => json.map((e) => SessionSummary.fromJson(e as Map<String, dynamic>)).toList());
  }

  Map<String, dynamic> _map(dynamic json) {
    if (json is Map<String, dynamic>) return json;
    throw const ApiProtocolException();
  }

  T _parse<T>(T Function() f) {
    try {
      return f();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiProtocolException();
    }
  }
}
