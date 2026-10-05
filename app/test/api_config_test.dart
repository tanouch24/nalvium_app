import 'package:flutter_test/flutter_test.dart';
import 'package:nalvium/core/config/api_config.dart';

void main() {
  group('release : aucune URL locale/privée comme URL de production', () {
    for (final url in [
      'http://localhost:8000',
      'https://localhost:8000',
      'http://127.0.0.1:8000',
      'https://127.0.0.1',
      'https://10.0.2.2:8000',
      'https://192.168.1.83:8001',
      'https://10.1.2.3',
      'https://172.16.0.5',
      'https://172.31.255.1',
      'https://169.254.1.1',
      'https://mon-mac.local',
      'http://api.nalvium.app', // http interdit en release
      '',
      'pas une url',
    ]) {
      test('refuse "$url"', () {
        expect(() => ApiConfig.resolve(url, release: true), throwsA(isA<ApiConfigException>()));
      });
    }

    test('accepte une vraie URL https publique', () {
      final c = ApiConfig.resolve('https://api.nalvium.app', release: true);
      expect(c.uri('/health').toString(), 'https://api.nalvium.app/health');
    });

    test('172.32.x n\'est pas privé', () {
      expect(() => ApiConfig.resolve('https://172.32.0.1', release: true), returnsNormally);
    });
  });

  group('debug', () {
    test('accepte le LAN en http', () {
      final c = ApiConfig.resolve('http://192.168.1.83:8001', release: false);
      expect(c.uri('/v1/sessions', {'active': 'true'}).toString(), 'http://192.168.1.83:8001/v1/sessions?active=true');
    });

    test('URL absente : erreur explicite (pas d\'IP codée en dur)', () {
      expect(() => ApiConfig.resolve('', release: false), throwsA(isA<ApiConfigException>()));
    });

    test('slash final normalisé', () {
      expect(ApiConfig.resolve('http://x.test:8000/', release: false).uri('/a').toString(), 'http://x.test:8000/a');
    });
  });
}
