import '../core/network/api_client.dart';
import '../core/network/api_exceptions.dart';
import '../domain/service_request.dart';

/// Demandes d'intervention (V1 : lead qualifié, aucun envoi à un professionnel).
abstract interface class ServiceRequestsRepository {
  Future<ServiceRequest> createDraft({String? equipmentId, String? summary, String? category});

  /// Brouillon lié à un diagnostic (le contexte est préparé côté serveur ; le brouillon existant est repris).
  Future<ServiceRequest> fromSession(String sessionId);
  Future<ServiceRequest> update(String id, Map<String, dynamic> fields);
  Future<ServiceRequest> selectMedia(String id, List<String> mediaIds);
  Future<ServiceRequest> submit(String id);
  Future<ServiceRequest> cancel(String id);
  Future<ServiceRequest> get(String id);
  Future<List<ServiceRequest>> list();

  /// Zone de service (affichage) et éligibilité rapide ville + code postal. Aucune position GPS.
  Future<ServiceAreaInfo> serviceArea();
  Future<AreaCheck> checkArea(String city, String postalCode);
}

class HttpServiceRequestsRepository implements ServiceRequestsRepository {
  HttpServiceRequestsRepository(this._api);
  final ApiClient _api;

  @override
  Future<ServiceRequest> createDraft({String? equipmentId, String? summary, String? category}) => _one(
    _api.postJson('/v1/service-requests', body: {'equipment_id': ?equipmentId, 'problem_summary': ?summary, 'category': ?category}),
  );

  @override
  Future<ServiceRequest> fromSession(String sessionId) => _one(_api.postJson('/v1/sessions/$sessionId/service-request'));

  @override
  Future<ServiceRequest> update(String id, Map<String, dynamic> fields) => _one(_api.patchJson('/v1/service-requests/$id', body: fields));

  @override
  Future<ServiceRequest> selectMedia(String id, List<String> mediaIds) => _one(_api.putJson('/v1/service-requests/$id/media', body: {'media_ids': mediaIds}));

  @override
  Future<ServiceRequest> submit(String id) => _one(
    _api.postJson('/v1/service-requests/$id/submit', body: {'consent': true, 'consent_version': kConsentVersion}),
  );

  @override
  Future<ServiceRequest> cancel(String id) => _one(_api.postJson('/v1/service-requests/$id/cancel'));

  @override
  Future<ServiceRequest> get(String id) => _one(_api.getJson('/v1/service-requests/$id'));

  @override
  Future<List<ServiceRequest>> list() async {
    final json = await _api.getJson('/v1/service-requests');
    if (json is! List) throw const ApiProtocolException();
    try {
      return [for (final e in json) ServiceRequest.fromJson(e as Map<String, dynamic>)];
    } catch (_) {
      throw const ApiProtocolException();
    }
  }

  @override
  Future<ServiceAreaInfo> serviceArea() async {
    final json = await _api.getJson('/v1/service-area');
    if (json is! Map<String, dynamic>) throw const ApiProtocolException();
    return ServiceAreaInfo.fromJson(json);
  }

  @override
  Future<AreaCheck> checkArea(String city, String postalCode) async {
    final json = await _api.postJson('/v1/service-area/check', body: {'city': city, 'postal_code': postalCode});
    if (json is! Map<String, dynamic>) throw const ApiProtocolException();
    return AreaCheck.fromJson(json);
  }

  Future<ServiceRequest> _one(Future<dynamic> call) async {
    final json = await call;
    if (json is! Map<String, dynamic>) throw const ApiProtocolException();
    try {
      return ServiceRequest.fromJson(json);
    } catch (_) {
      throw const ApiProtocolException();
    }
  }
}
