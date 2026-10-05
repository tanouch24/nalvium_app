import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nalvium/core/config/api_config.dart';
import 'package:nalvium/core/network/api_client.dart';
import 'package:nalvium/core/network/api_exceptions.dart';

const _id = '3f2b8a1e-6c1d-4a55-9d7e-0a1b2c3d4e5f';

ApiClient client(MockClientHandler handler, {List<String>? logs, Duration timeout = const Duration(seconds: 2)}) => ApiClient(
      config: ApiConfig.resolve('http://192.168.1.83:8001', release: false),
      installId: () async => _id,
      httpClient: MockClient(handler),
      timeout: timeout,
      analysisTimeout: timeout,
      log: logs?.add,
    );

void main() {
  connectionTimeoutTests();
  test('envoie l\'identité anonyme et décode le JSON', () async {
    late http.Request seen;
    final api = client((r) async {
      seen = r;
      return http.Response('{"ok":true}', 200);
    });
    final json = await api.getJson('/v1/sessions', query: {'active': 'true'});
    expect(json, {'ok': true});
    expect(seen.headers['X-Nalvium-Install-Id'], _id);
    expect(seen.url.path, '/v1/sessions');
  });

  test('POST JSON', () async {
    late http.Request seen;
    final api = client((r) async {
      seen = r;
      return http.Response('{"id":"s1"}', 201);
    });
    await api.postJson('/v1/sessions/s1/turn', body: {'kind': 'answer', 'text': 'Oui'});
    expect(jsonDecode(seen.body), {'kind': 'answer', 'text': 'Oui'});
    expect(seen.headers['Content-Type'], contains('application/json'));
  });

  test('upload multipart', () async {
    final file = File('${Directory.systemTemp.path}/up.jpg')..writeAsBytesSync([1, 2, 3]);
    late http.BaseRequest seen;
    final api = client((r) async {
      seen = r;
      return http.Response('{"id":"m1"}', 201);
    });
    expect(await api.postFile('/v1/sessions/s1/media', field: 'file', filePath: file.path), {'id': 'm1'});
    expect(seen, isA<http.Request>());
    expect(seen.headers['content-type'], contains('multipart/form-data'));
  });

  test('503 → ApiHttpException(isAnalysisUnavailable)', () async {
    final api = client((_) async => http.Response('{"detail":"analysis_unavailable"}', 503));
    expect(
      api.postJson('/x', analysis: true),
      throwsA(isA<ApiHttpException>().having((e) => e.isAnalysisUnavailable, 'unavailable', true).having((e) => e.code, 'code', 'analysis_unavailable')),
    );
  });

  test('erreur serveur non JSON → ApiHttpException sans plantage', () async {
    final api = client((_) async => http.Response('<html>oops</html>', 500));
    expect(api.getJson('/x'), throwsA(isA<ApiHttpException>().having((e) => e.status, 'status', 500)));
  });

  test('SocketException → ApiNetworkException', () async {
    final api = client((_) async => throw const SocketException('down'));
    expect(api.getJson('/x'), throwsA(isA<ApiNetworkException>()));
  });

  test('ClientException → ApiNetworkException', () async {
    final api = client((_) async => throw http.ClientException('down'));
    expect(api.getJson('/x'), throwsA(isA<ApiNetworkException>()));
  });

  test('timeout → ApiTimeoutException', () async {
    final api = client((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return http.Response('{}', 200);
    }, timeout: const Duration(milliseconds: 50));
    await expectLater(api.getJson('/x'), throwsA(isA<ApiTimeoutException>()));
    await Future<void>.delayed(const Duration(milliseconds: 450)); // laisse le faux serveur finir
  });

  test('JSON invalide → ApiProtocolException', () async {
    final api = client((_) async => http.Response('pas du json', 200));
    expect(api.getJson('/x'), throwsA(isA<ApiProtocolException>()));
  });

  test('logs DEV : seulement méthode+chemin, statut, durée — aucune donnée sensible', () async {
    final logs = <String>[];
    final api = client((_) async => http.Response.bytes(utf8.encode('{"secret":"conversation privée","photo":"base64XYZ"}'), 200), logs: logs);
    await api.postJson('/v1/sessions/s1/turn', body: {'kind': 'answer', 'text': 'Mon adresse est 12 rue X, mon numéro 0612345678'});
    expect(logs[0], '[API] POST /v1/sessions/s1/turn');
    expect(logs[1], '[API] status=200');
    expect(logs[2], matches(r'^\[API\] duration=\d+ms$'));
    final all = logs.join('\n');
    for (final forbidden in [_id, 'adresse', '0612345678', 'conversation privée', 'base64XYZ', 'X-Nalvium']) {
      expect(all.contains(forbidden), isFalse, reason: 'log fuite: $forbidden');
    }
    expect(all.contains('192.168.1.83'), isFalse); // pas d'hôte non plus : chemin seulement
  });
}

void connectionTimeoutTests() {
  test('client par défaut : connexion vers un hôte injoignable → ApiNetworkException rapide', () async {
    // Port fermé en local : la connexion est refusée immédiatement (SocketException) → erreur réseau typée.
    final api = ApiClient(
      config: ApiConfig.resolve('http://127.0.0.1:1', release: false),
      installId: () async => _id,
      timeout: const Duration(seconds: 5),
      log: (_) {},
    );
    await expectLater(api.getJson('/health'), throwsA(isA<ApiNetworkException>()));
  });
}
