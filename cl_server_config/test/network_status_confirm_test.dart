import 'package:cl_server_config/cl_server_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Runs [body] with a container whose `/health` answers come from
/// [answers], one per request, the last repeating.
Future<void> withHealth(
  List<int> answers,
  Future<void> Function(ProviderContainer container, List<Uri> requests) body,
) async {
  final requests = <Uri>[];
  await http.runWithClient(
    () async {
      final container = ProviderContainer(
        overrides: [
          serverConfigProvider.overrideWithValue(
            const ServerConfig(baseUrl: 'https://api.example.com/v1'),
          ),
        ],
      );
      addTearDown(container.dispose);
      await body(container, requests);
    },
    () => MockClient((request) async {
      requests.add(request.url);
      final index = requests.length - 1;
      return http.Response(
        '',
        answers[index < answers.length ? index : answers.length - 1],
      );
    }),
  );
}

Future<void> until(bool Function() done) async {
  for (var i = 0; i < 200 && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

void main() {
  test(
    'Issue 163: one failed health check leaves the status online',
    () async {
      await withHealth([503, 200], (container, requests) async {
        container.read(networkStatusProvider.notifier).checkNow();
        await until(() => requests.isNotEmpty);
        await pumpEventQueue();
        expect(container.read(networkStatusProvider), NetworkStatus.online);

        await until(() => requests.length >= 2);
        await pumpEventQueue();
        expect(requests, hasLength(2));
        expect(container.read(networkStatusProvider), NetworkStatus.online);
      });
    },
  );

  test(
    'Issue 163: a second failed health check reports the server unavailable',
    () async {
      await withHealth([503], (container, requests) async {
        container.read(networkStatusProvider.notifier).checkNow();
        await until(
          () => container.read(networkStatusProvider) != NetworkStatus.online,
        );
        expect(requests, hasLength(2));
        expect(
          container.read(networkStatusProvider),
          NetworkStatus.serverUnavailable,
        );
      });
    },
  );

  test(
    'Issue 163: once failed, one more failed check needs no confirmation',
    () async {
      await withHealth([503, 503, 503], (container, requests) async {
        final monitor = container.read(networkStatusProvider.notifier)
          ..checkNow();
        await until(
          () => container.read(networkStatusProvider) != NetworkStatus.online,
        );
        monitor.checkNow();
        await until(() => requests.length >= 3);
        await pumpEventQueue();
        expect(requests, hasLength(3));
        expect(
          container.read(networkStatusProvider),
          NetworkStatus.serverUnavailable,
        );
      });
    },
  );
}
