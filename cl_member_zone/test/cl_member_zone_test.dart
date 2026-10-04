import 'package:cl_server_config/cl_server_config.dart' show ServerConfig;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ServerConfig equality', () {
    const a = ServerConfig(baseUrl: 'https://api.example.com/v1');
    const b = ServerConfig(baseUrl: 'https://api.example.com/v1');
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });
}
