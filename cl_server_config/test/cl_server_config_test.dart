import 'package:cl_server_config/cl_server_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServerConfig', () {
    test('equality', () {
      const a = ServerConfig(baseUrl: 'https://api.example.com/v1');
      const b = ServerConfig(baseUrl: 'https://api.example.com/v1');
      const c = ServerConfig(baseUrl: 'https://other.com/v1');

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('copyWith', () {
      const config = ServerConfig(baseUrl: 'https://api.example.com/v1');
      final copied = config.copyWith(baseUrl: 'https://other.com/v1');

      expect(copied.baseUrl, 'https://other.com/v1');
      expect(config.baseUrl, 'https://api.example.com/v1');
    });

    test('toMap and fromMap', () {
      const config = ServerConfig(baseUrl: 'https://api.example.com/v1');
      final map = config.toMap();
      final restored = ServerConfig.fromMap(map);

      expect(restored, equals(config));
    });

    test('toJson and fromJson', () {
      const config = ServerConfig(baseUrl: 'https://api.example.com/v1');
      final jsonStr = config.toJson();
      final restored = ServerConfig.fromJson(jsonStr);

      expect(restored, equals(config));
    });

    test('Issue 144: toString names the API base URL only', () {
      const config = ServerConfig(baseUrl: 'https://api.example.com/v1');
      expect(
        config.toString(),
        'ServerConfig(baseUrl: https://api.example.com/v1)',
      );
    });

    test('Issue 144: carries no website origin', () {
      final config = ServerConfig.fromMap(const {
        'baseUrl': 'https://api.example.com/v1',
        'websiteBaseUrl': 'https://example.com',
      });

      expect(config, const ServerConfig(baseUrl: 'https://api.example.com/v1'));
      expect(config.toMap(), {'baseUrl': 'https://api.example.com/v1'});
    });
  });
}
