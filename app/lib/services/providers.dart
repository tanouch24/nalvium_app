import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/analytics/analytics.dart';
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exceptions.dart';
import '../data/account_repository.dart';
import '../data/home_repository.dart';
import '../data/service_requests_repository.dart';
import '../data/sessions_repository.dart';
import '../domain/equipment.dart';
import '../domain/service_request.dart';
import '../domain/session.dart';
import 'install_id_store.dart';
import 'photo_capture_service.dart';
import 'video_recorder_service.dart';

const _debugPhoto = String.fromEnvironment('NALVIUM_DEBUG_PHOTO');

/// Sink d'analytics : aucun par défaut (NoOp). Les tests le remplacent par un faux.
final analyticsSinkProvider = Provider<AnalyticsSink>(
  (ref) => const NoOpAnalytics(),
);
final analyticsProvider = Provider<Analytics>(
  (ref) => Analytics(ref.watch(analyticsSinkProvider)),
);

final photoCaptureServiceProvider = Provider<PhotoCaptureService>(
  (ref) => kDebugMode && _debugPhoto.isNotEmpty
      ? const FixedFilePhotoCaptureService(_debugPhoto)
      : ImagePickerPhotoCaptureService(),
);

final installIdStoreProvider = Provider<InstallIdStore>(
  (ref) => InstallIdStore(),
);

/// Résultat de la validation de l'URL backend (erreur typée si absente/interdite).
final apiConfigProvider = Provider<ApiConfig>((ref) {
  try {
    return ApiConfig.resolve(ApiConfig.compiledUrl, release: kReleaseMode);
  } on ApiConfigException catch (e) {
    throw ApiNotConfigured(e.reason);
  }
});

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    config: ref.watch(apiConfigProvider),
    installId: ref.watch(installIdStoreProvider).getOrCreate,
  ),
);

final sessionsRepositoryProvider = Provider<SessionsRepository>(
  (ref) => HttpSessionsRepository(ref.watch(apiClientProvider)),
);

/// Incrémenté quand une session change : les listes (Accueil, Historique) se rechargent.
class SessionsRevision extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final sessionsRevisionProvider = NotifierProvider<SessionsRevision, int>(
  SessionsRevision.new,
);

final serviceRequestsRepositoryProvider = Provider<ServiceRequestsRepository>(
  (ref) => HttpServiceRequestsRepository(ref.watch(apiClientProvider)),
);

/// Incrémenté quand une demande change (envoi, annulation) : les listes se rechargent.
class RequestsRevision extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final requestsRevisionProvider = NotifierProvider<RequestsRevision, int>(RequestsRevision.new);

/// Zone de service (nom + rayon) fournie par le serveur ; null si indisponible (la note n'est alors pas affichée).
final serviceAreaProvider = FutureProvider<ServiceAreaInfo?>((ref) async {
  try {
    return await ref.watch(serviceRequestsRepositoryProvider).serviceArea();
  } on ApiException {
    return null;
  }
});

final requestsProvider = FutureProvider.autoDispose<List<ServiceRequest>>((ref) {
  ref.watch(requestsRevisionProvider);
  return ref.watch(serviceRequestsRepositoryProvider).list();
});

final requestProvider = FutureProvider.autoDispose.family<ServiceRequest, String>((ref, id) {
  ref.watch(requestsRevisionProvider);
  return ref.watch(serviceRequestsRepositoryProvider).get(id);
});

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HttpHomeRepository(ref.watch(apiClientProvider)),
);

/// Incrémenté quand la Maison change (ajout, édition, suppression, liaison) : les écrans se rechargent.
class HomeRevision extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final homeRevisionProvider = NotifierProvider<HomeRevision, int>(HomeRevision.new);

/// Maison : un seul appel groupé, aucun appel IA.
final homeProvider = FutureProvider.autoDispose<HomeData>((ref) {
  ref.watch(homeRevisionProvider);
  ref.watch(sessionsRevisionProvider); // les compteurs de diagnostics suivent les sessions
  return ref.watch(homeRepositoryProvider).getHome();
});

final equipmentDetailProvider = FutureProvider.autoDispose.family<EquipmentDetail, String>((ref, id) {
  ref.watch(homeRevisionProvider);
  ref.watch(sessionsRevisionProvider);
  return ref.watch(homeRepositoryProvider).getEquipment(id);
});

final activeSessionsProvider = FutureProvider.autoDispose<List<SessionSummary>>(
  (ref) {
    ref.watch(sessionsRevisionProvider);
    return ref.watch(sessionsRepositoryProvider).listSessions(activeOnly: true);
  },
);

/// Session complète (récapitulatif d'une session terminée).
final sessionProvider = FutureProvider.autoDispose.family<SessionState, String>(
  (ref, id) => ref.watch(sessionsRepositoryProvider).getSession(id),
);

final allSessionsProvider = FutureProvider.autoDispose<List<SessionSummary>>((
  ref,
) {
  ref.watch(sessionsRevisionProvider);
  return ref.watch(sessionsRepositoryProvider).listSessions();
});

/// URL + en-têtes pour afficher une photo privée (nécessite l'identité). Null si API non configurée.
class MediaImageSource {
  const MediaImageSource(this.url, this.headers);
  final String url;
  final Map<String, String> headers;
}

final mediaImageSourceProvider = FutureProvider.autoDispose
    .family<MediaImageSource?, String>((ref, mediaId) async {
      try {
        final config = ref.watch(apiConfigProvider);
        final headers = await ref.watch(apiClientProvider).authHeaders();
        return MediaImageSource(
          config.uri('/v1/media/$mediaId/thumbnail').toString(),
          headers,
        );
      } on ApiException {
        return null;
      }
    });

/// Fabrique d'enregistreur vidéo (les tests la remplacent par un faux, sans caméra).
final videoRecorderFactoryProvider = Provider<VideoRecorder Function()>((ref) => CameraVideoRecorder.new);

/// Taille d'un fichier local (surchargée en test).
final videoFileSizeProvider = Provider<Future<int> Function(String)>((ref) => (path) => File(path).length());

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => HttpAccountRepository(ref.watch(apiClientProvider)),
);

/// Après suppression des données : nouvelle identité anonyme, et plus aucune donnée de l'ancienne en mémoire.
Future<void> deleteAllMyData(WidgetRef ref) async {
  await ref.read(accountRepositoryProvider).deleteAll();
  await ref.read(installIdStoreProvider).reset();
  ref.read(sessionsRevisionProvider.notifier).bump();
  ref.read(homeRevisionProvider.notifier).bump();
  ref.read(requestsRevisionProvider.notifier).bump();
  ref.invalidate(serviceAreaProvider);
}
