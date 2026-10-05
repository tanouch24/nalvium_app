import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:http/io_client.dart';

import '../config/api_config.dart';
import 'api_exceptions.dart';

typedef ApiLog = void Function(String line);

/// Client HTTP Nalvium : URL de base, timeouts, erreurs typées, identité anonyme.
///
/// Logs (DEV seulement) : méthode + chemin, statut, durée. JAMAIS de corps, photo, en-têtes,
/// identifiant, conversation ou donnée personnelle.
class ApiClient {
  ApiClient({
    required this.config,
    required this.installId,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
    this.analysisTimeout = const Duration(seconds: 70),
    ApiLog? log,
  })  : _http = httpClient ?? _defaultClient(),
        _log = log ?? (kDebugMode ? (l) => debugPrint(l) : (_) {});

  /// Connexion limitée à 8 s : un backend injoignable est signalé vite (le délai long ne concerne que l'analyse).
  static http.Client _defaultClient() => IOClient(HttpClient()..connectionTimeout = const Duration(seconds: 8));

  final ApiConfig config;
  final Future<String> Function() installId;
  final Duration timeout;

  /// Délai plus long pour les appels qui déclenchent l'analyse IA.
  final Duration analysisTimeout;
  final http.Client _http;
  final ApiLog _log;

  Future<Map<String, String>> authHeaders() async => {'X-Nalvium-Install-Id': await installId()};

  Future<dynamic> getJson(String path, {Map<String, String>? query}) =>
      _send('GET', path, (headers) => http.Request('GET', config.uri(path, query))..headers.addAll(headers), timeout);

  Future<dynamic> postJson(String path, {Object? body, bool analysis = false}) => _send(
        'POST',
        path,
        (headers) {
          final req = http.Request('POST', config.uri(path))..headers.addAll(headers);
          if (body != null) {
            req.headers['Content-Type'] = 'application/json';
            req.body = jsonEncode(body);
          }
          return req;
        },
        analysis ? analysisTimeout : timeout,
      );

  Future<dynamic> postFile(
    String path, {
    required String field,
    required String filePath,
    String filename = 'photo.jpg',
    String? contentType,
    Duration timeout = const Duration(seconds: 45),
  }) =>
      _send(
        'POST',
        path,
        (headers) => http.MultipartRequest('POST', config.uri(path))
          ..headers.addAll(headers)
          ..files.add(_fileSync(field, filePath, filename, contentType)),
        timeout,
      );

  http.MultipartFile _fileSync(String field, String path, String filename, String? contentType) {
    final bytes = File(path).readAsBytesSync();
    return http.MultipartFile.fromBytes(
      field,
      bytes,
      filename: filename,
      contentType: contentType == null ? null : MediaType.parse(contentType),
    );
  }

  Future<dynamic> _send(
    String method,
    String path,
    http.BaseRequest Function(Map<String, String> headers) build,
    Duration limit,
  ) async {
    final watch = Stopwatch()..start();
    _log('[API] $method $path');
    try {
      final request = build(await authHeaders());
      final streamed = await _http.send(request).timeout(limit);
      final response = await http.Response.fromStream(streamed).timeout(limit);
      _log('[API] status=${response.statusCode}');
      _log('[API] duration=${watch.elapsedMilliseconds}ms');
      return _decode(response);
    } on ApiException {
      _log('[API] duration=${watch.elapsedMilliseconds}ms');
      rethrow;
    } on TimeoutException {
      _log('[API] status=timeout');
      _log('[API] duration=${watch.elapsedMilliseconds}ms');
      throw const ApiTimeoutException();
    } on SocketException {
      _log('[API] status=network_error');
      throw const ApiNetworkException();
    } on http.ClientException {
      _log('[API] status=network_error');
      throw const ApiNetworkException();
    } on FileSystemException {
      throw const ApiProtocolException();
    }
  }

  dynamic _decode(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (r.bodyBytes.isEmpty) return null;
      try {
        return jsonDecode(utf8.decode(r.bodyBytes));
      } on FormatException {
        throw const ApiProtocolException();
      }
    }
    String? code;
    try {
      final body = jsonDecode(utf8.decode(r.bodyBytes));
      if (body is Map && body['detail'] is String) code = body['detail'] as String;
    } on FormatException {
      // corps non JSON : on garde seulement le statut
    }
    throw ApiHttpException(r.statusCode, code);
  }
}
