import '../core/network/api_client.dart';

/// Suppression des données rattachées à l'identité anonyme de cette installation.
abstract class AccountRepository {
  Future<void> deleteAll();
}

class HttpAccountRepository implements AccountRepository {
  HttpAccountRepository(this._api);
  final ApiClient _api;

  @override
  Future<void> deleteAll() async {
    await _api.deleteJson('/v1/me');
  }
}
