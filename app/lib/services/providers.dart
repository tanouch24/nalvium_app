import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exceptions.dart';
import '../data/sessions_repository.dart';
import '../domain/session.dart';
import 'install_id_store.dart';
import 'photo_capture_service.dart';

final photoCaptureServiceProvider = Provider<PhotoCaptureService>((ref) => ImagePickerPhotoCaptureService());

final installIdStoreProvider = Provider<InstallIdStore>((ref) => InstallIdStore());

/// Résultat de la validation de l'URL backend (erreur typée si absente/interdite).
final apiConfigProvider = Provider<ApiConfig>((ref) {
  try {
    return ApiConfig.resolve(ApiConfig.compiledUrl, release: kReleaseMode);
  } on ApiConfigException catch (e) {
    throw ApiNotConfigured(e.reason);
  }
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(
      config: ref.watch(apiConfigProvider),
      installId: ref.watch(installIdStoreProvider).getOrCreate,
    ));

final sessionsRepositoryProvider =
    Provider<SessionsRepository>((ref) => HttpSessionsRepository(ref.watch(apiClientProvider)));

/// Incrémenté quand une session change : les listes (Accueil, Historique) se rechargent.
class SessionsRevision extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final sessionsRevisionProvider = NotifierProvider<SessionsRevision, int>(SessionsRevision.new);

final activeSessionsProvider = FutureProvider.autoDispose<List<SessionSummary>>((ref) {
  ref.watch(sessionsRevisionProvider);
  return ref.watch(sessionsRepositoryProvider).listSessions(activeOnly: true);
});

final allSessionsProvider = FutureProvider.autoDispose<List<SessionSummary>>((ref) {
  ref.watch(sessionsRevisionProvider);
  return ref.watch(sessionsRepositoryProvider).listSessions();
});

/// URL + en-têtes pour afficher une photo privée (nécessite l'identité). Null si API non configurée.
class MediaImageSource {
  const MediaImageSource(this.url, this.headers);
  final String url;
  final Map<String, String> headers;
}

final mediaImageSourceProvider = FutureProvider.autoDispose.family<MediaImageSource?, String>((ref, mediaId) async {
  try {
    final config = ref.watch(apiConfigProvider);
    final headers = await ref.watch(apiClientProvider).authHeaders();
    return MediaImageSource(config.uri('/v1/media/$mediaId/content').toString(), headers);
  } on ApiException {
    return null;
  }
});
