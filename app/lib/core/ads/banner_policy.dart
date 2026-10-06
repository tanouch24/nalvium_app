/// OÙ la bannière discrète peut apparaître. Un seul endroit décide : les écrans ne gèrent jamais la bannière.
///
/// Autorisé : écrans de navigation et de consultation (onglets, historique, réglages, fiche équipement,
/// récapitulatif d'un diagnostic terminé).
/// Jamais : capture et aperçu photo/vidéo, saisie, analyse IA, session de diagnostic (questions, photos demandées,
/// instructions, vérification, arrêt de sécurité, professionnel, RÉSOLU), formulaires d'équipement.
abstract final class BannerPolicy {
  static const tabs = {'/home', '/house', '/repair', '/community'};

  static bool isTab(String path) => tabs.contains(path);

  static bool allowedFor(String path) {
    if (isTab(path)) return true;
    if (path == '/history' || path == '/settings') return true;
    final segments = Uri.parse(path).pathSegments;
    // Détail d'une demande d'intervention : /requests/<id> (jamais les écrans de création /help/*)
    if (segments.length == 2 && segments[0] == 'requests') return true;
    // Communauté : enregistrés et détail d'une publication (jamais la création, l'aperçu ni l'édition).
    if (path == '/community/saved') return true;
    if (segments.length == 3 && segments[0] == 'community' && segments[1] == 'post') return true;
    // Fiche équipement : /equipment/<id> (pas add, identify, ni <id>/edit)
    if (segments.length == 2 && segments[0] == 'equipment') {
      return segments[1] != 'add' && segments[1] != 'identify';
    }
    // Récapitulatif : /session/<id>/summary (la session active /session/<id> n'est JAMAIS autorisée)
    if (segments.length == 3 && segments[0] == 'session' && segments[2] == 'summary') return true;
    return false;
  }
}
