/// Configuration de l'URL du backend, fournie à la compilation :
///   flutter run --dart-define=NALVIUM_API_URL=http://IP_LAN_DU_MAC:8001
/// En release, une URL locale ou privée est refusée : elle ne peut pas être une URL de production.
class ApiConfigException implements Exception {
  const ApiConfigException(this.reason);
  final String reason;
  @override
  String toString() => 'ApiConfigException($reason)';
}

class ApiConfig {
  const ApiConfig._(this.baseUrl);

  final Uri baseUrl;

  static const _fromEnv = String.fromEnvironment('NALVIUM_API_URL');

  /// URL compilée dans l'app (peut être vide).
  static String get compiledUrl => _fromEnv;

  /// Valide [raw]. Lance [ApiConfigException] si absente ou interdite pour ce mode.
  static ApiConfig resolve(String raw, {required bool release}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) throw const ApiConfigException('missing');
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      throw const ApiConfigException('invalid');
    }
    if (release) {
      if (uri.scheme != 'https') throw const ApiConfigException('release_requires_https');
      if (isLocalOrPrivateHost(uri.host)) throw const ApiConfigException('release_forbids_local_host');
    }
    final path = uri.path.endsWith('/') ? uri.path.substring(0, uri.path.length - 1) : uri.path;
    return ApiConfig._(uri.replace(path: path));
  }

  Uri uri(String path, [Map<String, String>? query]) =>
      baseUrl.replace(path: '${baseUrl.path}$path', queryParameters: query);

  static bool isLocalOrPrivateHost(String host) {
    final h = host.toLowerCase();
    if (h == 'localhost' || h.endsWith('.localhost') || h.endsWith('.local') || h == '10.0.2.2' || h == '::1') {
      return true;
    }
    final parts = h.split('.');
    if (parts.length == 4 && parts.every((p) => int.tryParse(p) != null)) {
      final a = int.parse(parts[0]);
      final b = int.parse(parts[1]);
      if (a == 127 || a == 10 || a == 0) return true;
      if (a == 192 && b == 168) return true;
      if (a == 172 && b >= 16 && b <= 31) return true;
      if (a == 169 && b == 254) return true;
    }
    return false;
  }
}
