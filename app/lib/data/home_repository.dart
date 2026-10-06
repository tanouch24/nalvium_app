import '../core/network/api_client.dart';
import '../core/network/api_exceptions.dart';
import '../domain/equipment.dart';
import '../domain/session.dart';

/// Maison : équipements, photos privées, identification sur photo, liaison aux diagnostics.
abstract interface class HomeRepository {
  Future<HomeData> getHome();
  Future<EquipmentDetail> getEquipment(String id);
  Future<EquipmentDetail> createEquipment(EquipmentDraft draft);

  /// Seules les clés fournies sont modifiées ; une valeur null efface (marque, modèle, pièce, photo).
  Future<EquipmentDetail> updateEquipment(String id, Map<String, dynamic> fields);
  Future<void> deleteEquipment(String id);

  /// Photo privée d'équipement (sans session). Retourne l'identifiant du média.
  Future<String> uploadEquipmentPhoto(String filePath);

  /// Abandon explicite : supprime tout de suite une photo temporaire non utilisée (échec silencieux).
  Future<void> discardEquipmentPhoto(String mediaId);

  /// Identification sur photo : ce n'est PAS un diagnostic.
  Future<EquipmentIdentification> identify(String mediaId);

  /// [equipmentId] null = détacher.
  Future<SessionState> linkSession(String sessionId, String? equipmentId);
  Future<EquipmentSuggestions> suggestions(String sessionId);

  /// Recherche de la notice officielle (marque + référence uniquement). Pas un diagnostic.
  Future<ManualSearchResult> searchManual(String equipmentId);
  Future<ManualSearchResult> confirmManual(String equipmentId);
  Future<void> deleteManual(String equipmentId);
  Future<ManualPage> manualPage(String equipmentId, int page);
}

class HttpHomeRepository implements HomeRepository {
  HttpHomeRepository(this._api);
  final ApiClient _api;

  @override
  Future<HomeData> getHome() => _read(_api.getJson('/v1/home'), HomeData.fromJson);

  @override
  Future<EquipmentDetail> getEquipment(String id) =>
      _read(_api.getJson('/v1/equipment/$id'), EquipmentDetail.fromJson);

  @override
  Future<EquipmentDetail> createEquipment(EquipmentDraft draft) =>
      _read(_api.postJson('/v1/equipment', body: draft.toJson()), EquipmentDetail.fromJson);

  @override
  Future<EquipmentDetail> updateEquipment(String id, Map<String, dynamic> fields) =>
      _read(_api.patchJson('/v1/equipment/$id', body: fields), EquipmentDetail.fromJson);

  @override
  Future<void> deleteEquipment(String id) async {
    await _api.deleteJson('/v1/equipment/$id');
  }

  @override
  Future<String> uploadEquipmentPhoto(String filePath) => _read(
    _api.postFile('/v1/equipment/photo', field: 'file', filePath: filePath),
    (j) => j['id'] as String,
  );

  @override
  Future<void> discardEquipmentPhoto(String mediaId) async {
    try {
      await _api.deleteJson('/v1/equipment/photo/$mediaId');
    } on ApiException {
      // pas de nettoyage garanti hors ligne : documenté (Phase 7), jamais bloquant pour l'utilisateur
    }
  }

  @override
  Future<EquipmentIdentification> identify(String mediaId) => _read(
    _api.postJson('/v1/equipment/identify', body: {'media_id': mediaId}, analysis: true),
    EquipmentIdentification.fromJson,
  );

  @override
  Future<SessionState> linkSession(String sessionId, String? equipmentId) => _read(
    _api.postJson('/v1/sessions/$sessionId/equipment', body: {'equipment_id': equipmentId}),
    SessionState.fromJson,
  );

  @override
  Future<EquipmentSuggestions> suggestions(String sessionId) =>
      _read(_api.getJson('/v1/sessions/$sessionId/equipment/suggestions'), EquipmentSuggestions.fromJson);

  @override
  Future<ManualSearchResult> searchManual(String equipmentId) => _read(
    _api.postJson('/v1/equipment/$equipmentId/manual/search', analysis: true, longWait: true),
    ManualSearchResult.fromJson,
  );

  @override
  Future<ManualSearchResult> confirmManual(String equipmentId) =>
      _read(_api.postJson('/v1/equipment/$equipmentId/manual/confirm'), ManualSearchResult.fromJson);

  @override
  Future<void> deleteManual(String equipmentId) async {
    await _api.deleteJson('/v1/equipment/$equipmentId/manual');
  }

  @override
  Future<ManualPage> manualPage(String equipmentId, int page) =>
      _read(_api.getJson('/v1/equipment/$equipmentId/manual/pages/$page'), ManualPage.fromJson);

  /// Réponse inattendue du serveur = erreur de protocole typée (jamais un crash).
  Future<T> _read<T>(Future<dynamic> call, T Function(Map<String, dynamic>) build) async {
    final json = await call;
    if (json is! Map<String, dynamic>) throw const ApiProtocolException();
    try {
      return build(json);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiProtocolException();
    }
  }
}
