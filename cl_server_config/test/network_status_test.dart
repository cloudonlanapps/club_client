import 'dart:async';

import 'package:cl_server_config/cl_server_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final answers = <String, http.Response Function()>{
    'a server error': () => http.Response('', 503),
    'a failed request': () => throw Exception('boom'),
  };

  for (final MapEntry(key: name, value: answer) in answers.entries) {
    test(
      'Issue 256: $name after the container is disposed is ignored',
      () async {
        final requested = Completer<void>();
        final release = Completer<void>();

        await http.runWithClient(
          () async {
            final container = ProviderContainer(
              overrides: [
                serverConfigProvider.overrideWithValue(
                  const ServerConfig(baseUrl: 'https://api.example.com/v1'),
                ),
              ],
            );
            container.read(networkStatusProvider.notifier).checkNow();
            await requested.future;
            container.dispose();
            release.complete();
            // Let the health check finish after its notifier is gone.
            await pumpEventQueue();
          },
          () => MockClient((_) async {
            requested.complete();
            await release.future;
            return answer();
          }),
        );
      },
    );
  }
}
