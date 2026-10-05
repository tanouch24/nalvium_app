/// Erreurs typées de l'API : l'UI choisit son message selon le type, jamais selon un texte brut.
sealed class ApiException implements Exception {
  const ApiException();
}

/// L'URL du backend n'est pas (ou mal) configurée.
class ApiNotConfigured extends ApiException {
  const ApiNotConfigured(this.reason);
  final String reason;
}

/// Pas de réseau / serveur injoignable.
class ApiNetworkException extends ApiException {
  const ApiNetworkException();
}

class ApiTimeoutException extends ApiException {
  const ApiTimeoutException();
}

/// Le serveur a répondu avec une erreur.
class ApiHttpException extends ApiException {
  const ApiHttpException(this.status, this.code);
  final int status;
  final String? code;

  /// 503 `analysis_unavailable` : le moteur IA n'est pas disponible côté serveur.
  bool get isAnalysisUnavailable => status == 503;
}

class ApiProtocolException extends ApiException {
  const ApiProtocolException();
}
