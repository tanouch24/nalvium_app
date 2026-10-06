import '../core/network/api_client.dart';
import '../core/network/api_exceptions.dart';
import '../domain/community.dart';

/// Communauté : publications, médias publics dérivés, Utile, enregistrés, commentaires, signalements.
abstract interface class CommunityRepository {
  Future<CommunityPage> feed({String? cursor});
  Future<CommunityPage> saved({String? cursor});
  Future<CommunityPost> post(String id);
  Future<CommunityPost> create({
    required String title,
    required String solution,
    String? category,
    String? materials,
    String? mediaId,
  });
  Future<CommunityPost> update(String id, Map<String, dynamic> fields);
  Future<void> delete(String id);
  Future<CommunityPost> setHelpful(String id, bool on);
  Future<CommunityPost> setSaved(String id, bool on);
  Future<CommentPage> comments(String postId, {String? cursor});
  Future<CommunityComment> addComment(String postId, String body);
  Future<void> deleteComment(String commentId);

  /// Photo prise pour la Communauté : copie publique distincte (brouillon). Retourne l'id du média public.
  Future<String> uploadPhoto(String filePath);

  /// Copie PUBLIQUE d'une photo privée (consentement explicite enregistré côté serveur).
  Future<String> derivePrivatePhoto(String privateMediaId);
  Future<void> discardDraftPhoto(String mediaId);

  /// Retourne true si créé, false si déjà signalé par ce membre.
  Future<bool> reportPost(String postId, String reason, {String? details});
  Future<bool> reportComment(String commentId, String reason, {String? details});
}

class HttpCommunityRepository implements CommunityRepository {
  HttpCommunityRepository(this._api);
  final ApiClient _api;

  static Map<String, String> _q(String? cursor) => {'limit': '20', 'cursor': ?cursor};

  @override
  Future<CommunityPage> feed({String? cursor}) async =>
      _read(await _api.getJson('/v1/community/posts', query: _q(cursor)), CommunityPage.fromJson);

  @override
  Future<CommunityPage> saved({String? cursor}) async =>
      _read(await _api.getJson('/v1/community/saved', query: _q(cursor)), CommunityPage.fromJson);

  @override
  Future<CommunityPost> post(String id) async => _read(await _api.getJson('/v1/community/posts/$id'), CommunityPost.fromJson);

  @override
  Future<CommunityPost> create({required String title, required String solution, String? category, String? materials, String? mediaId}) async =>
      _read(
        await _api.postJson('/v1/community/posts', body: {
          'title': title,
          'solution': solution,
          'category': category,
          'materials': materials,
          'media_id': mediaId,
          'consent_public': true,
          'consent_version': kCommunityConsentVersion,
        }),
        CommunityPost.fromJson,
      );

  @override
  Future<CommunityPost> update(String id, Map<String, dynamic> fields) async =>
      _read(await _api.patchJson('/v1/community/posts/$id', body: fields), CommunityPost.fromJson);

  @override
  Future<void> delete(String id) async {
    await _api.deleteJson('/v1/community/posts/$id');
  }

  @override
  Future<CommunityPost> setHelpful(String id, bool on) async => _read(
    on ? await _api.putJson('/v1/community/posts/$id/helpful', body: const {}) : await _api.deleteJson('/v1/community/posts/$id/helpful'),
    CommunityPost.fromJson,
  );

  @override
  Future<CommunityPost> setSaved(String id, bool on) async => _read(
    on ? await _api.putJson('/v1/community/posts/$id/save', body: const {}) : await _api.deleteJson('/v1/community/posts/$id/save'),
    CommunityPost.fromJson,
  );

  @override
  Future<CommentPage> comments(String postId, {String? cursor}) async =>
      _read(await _api.getJson('/v1/community/posts/$postId/comments', query: _q(cursor)), CommentPage.fromJson);

  @override
  Future<CommunityComment> addComment(String postId, String body) async =>
      _read(await _api.postJson('/v1/community/posts/$postId/comments', body: {'body': body}), CommunityComment.fromJson);

  @override
  Future<void> deleteComment(String commentId) async {
    await _api.deleteJson('/v1/community/comments/$commentId');
  }

  @override
  Future<String> uploadPhoto(String filePath) async =>
      _read(await _api.postFile('/v1/community/media', field: 'file', filePath: filePath), (j) => j['id'] as String);

  @override
  Future<String> derivePrivatePhoto(String privateMediaId) async => _read(
    await _api.postJson('/v1/community/media/from-private', body: {'media_id': privateMediaId, 'consent_public': true}),
    (j) => j['id'] as String,
  );

  @override
  Future<void> discardDraftPhoto(String mediaId) async {
    try {
      await _api.deleteJson('/v1/community/media/$mediaId');
    } on ApiException {
      // nettoyage au mieux ; jamais bloquant
    }
  }

  @override
  Future<bool> reportPost(String postId, String reason, {String? details}) async => _read(
    await _api.postJson('/v1/community/posts/$postId/report', body: {'reason': reason, 'details': details}),
    (j) => j['created'] as bool,
  );

  @override
  Future<bool> reportComment(String commentId, String reason, {String? details}) async => _read(
    await _api.postJson('/v1/community/comments/$commentId/report', body: {'reason': reason, 'details': details}),
    (j) => j['created'] as bool,
  );

  T _read<T>(dynamic json, T Function(Map<String, dynamic>) build) {
    if (json is! Map<String, dynamic>) throw const ApiProtocolException();
    try {
      return build(json);
    } catch (_) {
      throw const ApiProtocolException();
    }
  }
}
