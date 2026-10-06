import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ads/ad_policy.dart';
import '../core/analytics/analytics.dart';
import '../core/ads/ads_service.dart';
import '../core/ads/google_ads_service.dart';
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exceptions.dart';
import '../data/account_repository.dart';
import '../data/community_repository.dart';
import '../data/home_repository.dart';
import '../data/service_requests_repository.dart';
import '../data/sessions_repository.dart';
import '../domain/community.dart';
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

final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => HttpCommunityRepository(ref.watch(apiClientProvider)),
);

/// État d'une liste paginée de publications (fil ou enregistrés).
class FeedState {
  const FeedState({this.items = const [], this.nextCursor, this.loading = true, this.loadingMore = false, this.error, this.moreError});
  final List<CommunityPost> items;
  final String? nextCursor;
  final bool loading;
  final bool loadingMore;
  final Object? error;
  final Object? moreError;
  bool get hasMore => nextCursor != null;
}

/// Fil national (saved=false) ou « Enregistrés » (saved=true). Curseur stable, aucun doublon.
class FeedNotifier extends Notifier<FeedState> {
  FeedNotifier(this.saved);
  final bool saved;

  @override
  FeedState build() {
    Future.microtask(refresh);
    return const FeedState();
  }

  Future<CommunityPage> _fetch(String? cursor) {
    final repo = ref.read(communityRepositoryProvider);
    return saved ? repo.saved(cursor: cursor) : repo.feed(cursor: cursor);
  }

  Future<void> refresh() async {
    state = FeedState(items: state.items, loading: true);
    try {
      final page = await _fetch(null);
      state = FeedState(items: page.items, nextCursor: page.nextCursor, loading: false);
    } on ApiException catch (e) {
      state = FeedState(items: state.items, loading: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    state = FeedState(items: state.items, nextCursor: state.nextCursor, loading: false, loadingMore: true);
    try {
      final page = await _fetch(state.nextCursor);
      final known = {for (final p in state.items) p.id};
      state = FeedState(items: [...state.items, for (final p in page.items) if (!known.contains(p.id)) p], nextCursor: page.nextCursor, loading: false);
    } on ApiException catch (e) {
      state = FeedState(items: state.items, nextCursor: state.nextCursor, loading: false, moreError: e);
    }
  }

  /// Met à jour une publication déjà affichée (Utile, enregistrement…), ou la retire.
  void replace(CommunityPost post) {
    if (saved && !post.saved) {
      state = FeedState(items: [for (final p in state.items) if (p.id != post.id) p], nextCursor: state.nextCursor, loading: state.loading);
    } else {
      state = FeedState(items: [for (final p in state.items) p.id == post.id ? post : p], nextCursor: state.nextCursor, loading: state.loading);
    }
  }

  void remove(String id) => state = FeedState(items: [for (final p in state.items) if (p.id != id) p], nextCursor: state.nextCursor, loading: state.loading);
}

final communityFeedProvider = NotifierProvider.family<FeedNotifier, FeedState, bool>(FeedNotifier.new);

final communityPostProvider = FutureProvider.autoDispose.family<CommunityPost, String>(
  (ref, id) => ref.watch(communityRepositoryProvider).post(id),
);

/// Image de la Communauté : `thumb` (liste) ou `large` (détail). Copies publiques dérivées, jamais un média privé.
final communityImageProvider = FutureProvider.autoDispose.family<MediaImageSource?, (String, String)>((ref, key) async {
  try {
    final config = ref.watch(apiConfigProvider);
    final headers = await ref.watch(apiClientProvider).authHeaders();
    return MediaImageSource(config.uri('/v1/community/media/${key.$1}/${key.$2}').toString(), headers);
  } on ApiException {
    return null;
  }
});

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

/// Publicités. Les tests surchargent ce provider (aucun SDK n'est chargé en test).
/// `--dart-define=NALVIUM_DISABLE_ADS=true` : développement / captures sans publicité.
const _adsDisabled = bool.fromEnvironment('NALVIUM_DISABLE_ADS');

const _debugBanner = bool.fromEnvironment('NALVIUM_DEBUG_BANNER');

final adsServiceProvider = Provider<AdsService>(
  (ref) => _adsDisabled
      ? const NoopAdsService()
      : (kDebugMode && _debugBanner)
      ? const PlaceholderBannerAdsService()
      : GoogleAdsService(
          policy: AdPolicy(counter: PrefsDiagnosticCounter()),
          onEvent: (e) => ref.read(analyticsProvider).log(e),
        ),
);

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
  ref.invalidate(communityFeedProvider);
  ref.invalidate(serviceAreaProvider);
}
