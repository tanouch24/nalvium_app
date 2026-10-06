/// Instrumentation PRODUIT minimale, sans SDK tiers : une abstraction (`AnalyticsSink`) et rien d'autre.
/// Aujourd'hui le sink par défaut ne fait RIEN ([NoOpAnalytics]) : aucun traceur n'est ajouté tant qu'une décision
/// explicite n'est pas prise. Les événements ne contiennent JAMAIS de donnée personnelle (voir [AnalyticsEvent]).
enum AnalyticsEvent {
  appOpened('app_opened'),
  diagnosticStarted('diagnostic_started'),
  diagnosticCompleted('diagnostic_completed'),
  diagnosticResolved('diagnostic_resolved'),
  safetyStop('safety_stop'),
  helpRequested('help_requested'),
  serviceRequestSubmitted('service_request_submitted'),
  serviceRequestOutOfZone('service_request_out_of_zone'),
  communityPostCreated('community_post_created'),
  communityHelpful('community_helpful'),
  communitySaved('community_saved'),
  adBannerImpression('ad_banner_impression'),
  adInterstitialShown('ad_interstitial_shown'),
  adAppOpenShown('ad_app_open_shown');

  const AnalyticsEvent(this.wire);
  final String wire;
}

/// Destination des événements (remplaçable : agrégation first-party, SDK choisi plus tard…).
abstract interface class AnalyticsSink {
  void log(AnalyticsEvent event, Map<String, Object> properties);
}

class NoOpAnalytics implements AnalyticsSink {
  const NoOpAnalytics();
  @override
  void log(AnalyticsEvent event, Map<String, Object> properties) {}
}

/// Seul point d'entrée de l'app : applique une LISTE BLANCHE de propriétés avant d'envoyer au sink.
/// Autorisé : `source` (diagnostic | direct | safety_stop | equipment | settings), `media_count` (entier).
/// Tout le reste (texte libre, téléphone, e-mail, ville, code postal, marque, commentaire, URL, id…) est ÉCARTÉ.
class Analytics {
  const Analytics(this._sink);
  final AnalyticsSink _sink;

  static const allowedSources = {
    'diagnostic',
    'direct',
    'safety_stop',
    'equipment',
    'photo',
    'description',
    'video',
  };

  void log(AnalyticsEvent event, {String? source, int? mediaCount}) {
    final props = <String, Object>{
      if (source != null && allowedSources.contains(source)) 'source': source,
      if (mediaCount != null && mediaCount >= 0 && mediaCount <= 10)
        'media_count': mediaCount,
    };
    try {
      _sink.log(event, props);
    } catch (_) {
      // L'instrumentation ne doit JAMAIS casser l'app.
    }
  }
}
