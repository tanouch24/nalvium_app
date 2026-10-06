import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';
import 'ad_policy.dart';
import 'ads_service.dart';

/// Implémentation Google Mobile Ads : UMP (consentement) → SDK → bannière / interstitiel / App Open.
/// IDs de TEST uniquement. Aucune donnée de diagnostic (photos, textes) n'est jamais transmise aux pubs.
class GoogleAdsService implements AdsService {
  GoogleAdsService({required this.policy, AdIds? ids}) : ids = ids ?? AdIds.forBuild();

  final AdPolicy policy;
  final AdIds ids;

  static const _appOpenMaxAge = Duration(hours: 4);
  static const _coldStartWindow = Duration(seconds: 6);

  final _launch = Stopwatch()..start();
  Future<void>? _init;
  bool ready = false;
  InterstitialAd? _interstitial;
  AppOpenAd? _appOpen;
  DateTime? _appOpenLoadedAt;
  bool _showing = false;
  bool _externalIntent = false;

  @override
  Future<void> initialize() => _init ??= _initialize();

  Future<void> _initialize() async {
    try {
      await _gatherConsent();
      if (!await ConsentInformation.instance.canRequestAds()) {
        debugPrint('[ADS] consentement : publicités non autorisées');
        return;
      }
      await MobileAds.instance.initialize();
      ready = true;
      debugPrint('[ADS] SDK initialisé (${AdIds.usesProduction ? 'production' : 'IDs de test'})');
      _loadInterstitial();
      _loadAppOpen(showWhenLoaded: true);
    } catch (e) {
      debugPrint('[ADS] initialisation impossible: ${e.runtimeType}');
    }
  }

  /// UMP : met à jour l'état du consentement puis affiche le formulaire s'il est requis.
  Future<void> _gatherConsent() {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => ConsentForm.loadAndShowConsentFormIfRequired((error) {
        if (error != null) debugPrint('[ADS] formulaire de consentement: ${error.errorCode}');
        if (!done.isCompleted) done.complete();
      }),
      (error) {
        debugPrint('[ADS] consentement indisponible: ${error.errorCode}');
        if (!done.isCompleted) done.complete();
      },
    );
    return done.future.timeout(const Duration(seconds: 20), onTimeout: () {});
  }

  // ── Bannière discrète (un seul bloc Nalvium, emplacements décidés par BannerPolicy) ───────────────────────────────────────────
  @override
  Widget buildBanner() => _AdaptiveBanner(service: this);

  // ── Interstitiel : avant chaque NOUVEAU diagnostic à partir du n°2 ──
  void _loadInterstitial() {
    if (!ready || _interstitial != null) return;
    InterstitialAd.load(
      adUnitId: ids.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (e) => debugPrint('[ADS] interstitiel non chargé: ${e.code}'),
      ),
    );
  }

  @override
  Future<void> beforeNewDiagnostic() async {
    try {
      final due = await policy.interstitialDueForNewDiagnostic();
      await policy.recordDiagnosticStarted();
      final ad = _interstitial;
      if (!due || !ready || ad == null || _showing) {
        if (due && ad == null) _loadInterstitial();
        return;
      }
      _interstitial = null;
      _showing = true;
      final dismissed = Completer<void>();
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (a) {
          a.dispose();
          _showing = false;
          policy.recordFullscreenShown();
          _loadInterstitial();
          if (!dismissed.isCompleted) dismissed.complete();
        },
        onAdFailedToShowFullScreenContent: (a, e) {
          a.dispose();
          _showing = false;
          _loadInterstitial();
          if (!dismissed.isCompleted) dismissed.complete();
        },
      );
      await ad.show();
      await dismissed.future.timeout(const Duration(seconds: 90), onTimeout: () => _showing = false);
    } catch (e) {
      _showing = false; // une pub ne doit jamais bloquer le diagnostic
    }
  }

  // ── App Open ──────────────────────────────────────────────────────
  void _loadAppOpen({bool showWhenLoaded = false}) {
    if (!ready || _appOpen != null) return;
    AppOpenAd.load(
      adUnitId: ids.appOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpen = ad;
          _appOpenLoadedAt = DateTime.now();
          // Démarrage à froid : on ne l'affiche que si elle arrive dans les premières secondes.
          if (showWhenLoaded && _launch.elapsed < _coldStartWindow) _showAppOpen(coldStart: true);
        },
        onAdFailedToLoad: (e) => debugPrint('[ADS] App Open non chargée: ${e.code}'),
      ),
    );
  }

  void _showAppOpen({bool coldStart = false, String route = '/home'}) {
    final ad = _appOpen;
    final loadedAt = _appOpenLoadedAt;
    if (ad == null || loadedAt == null || _showing) return;
    if (DateTime.now().difference(loadedAt) > _appOpenMaxAge) {
      ad.dispose();
      _appOpen = null;
      _loadAppOpen();
      return;
    }
    if (!policy.appOpenAllowed(route: route, backgroundFor: coldStart ? null : const Duration(days: 1), externalIntent: _externalIntent)) return;
    _appOpen = null;
    _showing = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _showing = false;
        policy.recordFullscreenShown();
        _loadAppOpen();
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        _showing = false;
        _loadAppOpen();
      },
    );
    ad.show();
  }

  @override
  Future<void> onAppResumed({required String route, required Duration backgroundFor}) async {
    if (!ready || _showing) return;
    if (!policy.appOpenAllowed(route: route, backgroundFor: backgroundFor, externalIntent: _externalIntent)) return;
    _showAppOpen(route: route);
  }

  @override
  Future<T> suspendAppOpen<T>(Future<T> Function() action) async {
    _externalIntent = true;
    try {
      return await action();
    } finally {
      // Le retour de la caméra système déclenche un « resumed » juste après : on garde le verrou un instant.
      Future<void>.delayed(const Duration(seconds: 2), () => _externalIntent = false);
    }
  }
}

/// Bannière adaptative ancrée. L'espace est réservé dès que la taille est connue (pas de saut de mise en page),
/// et libéré si aucune pub n'est disponible.
class _AdaptiveBanner extends StatefulWidget {
  const _AdaptiveBanner({required this.service});
  final GoogleAdsService service;

  @override
  State<_AdaptiveBanner> createState() => _AdaptiveBannerState();
}

class _AdaptiveBannerState extends State<_AdaptiveBanner> {
  BannerAd? _ad;
  double _height = 0;
  bool _failed = false;
  bool _started = false;
  int _attempt = 0;
  Timer? _retry;
  static const _retryDelays = [Duration(seconds: 20), Duration(seconds: 60), Duration(minutes: 3)];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load(MediaQuery.sizeOf(context).width.truncate());
  }

  Future<void> _load(int width) async {
    await widget.service.initialize();
    if (!widget.service.ready || !mounted) return;
    // Taille adaptative « standard » (≈ 50–60 dp) : la variante « large » est plus haute et prendrait trop de place.
    // ignore: deprecated_member_use
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;
    setState(() => _height = size.height.toDouble()); // espace réservé pendant le chargement
    final ad = BannerAd(
      adUnitId: widget.service.ids.banner,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() {});
        },
        onAdFailedToLoad: (ad, e) {
          ad.dispose();
          debugPrint('[ADS] bannière non chargée: ${e.code}');
          if (!mounted) return;
          setState(() {
            _failed = true; // l'espace est libéré tant qu'aucune pub n'est disponible
            _ad = null;
            _height = 0;
          });
          // Nouvelle tentative avec délai croissant (pas de rafale de requêtes).
          if (_attempt < _retryDelays.length) {
            _retry = Timer(_retryDelays[_attempt++], () {
              if (!mounted) return;
              setState(() => _failed = false);
              _load(MediaQuery.sizeOf(context).width.truncate());
            });
          }
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _retry?.cancel();
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed || _height == 0) return const SizedBox.shrink();
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        key: const Key('ad-banner'),
        height: _height,
        width: double.infinity,
        child: _ad == null ? null : AdWidget(ad: _ad!),
      ),
    );
  }
}
