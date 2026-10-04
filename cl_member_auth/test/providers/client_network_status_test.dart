import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_server_config/cl_server_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Issue 729: the authenticated [clientProvider] must wire every SDK request
/// to the reactive [networkStatusProvider] so the app recovers from a network
/// failure automatically — instead of each request surfacing its own raw
/// error.
///
/// Under [TestWidgetsFlutterBinding] all HTTP requests are stubbed to return
/// status 400, so a real connection-level failure cannot be produced here.
/// The unreachable → `checkNow()` logic is covered by the `RemoteStore` unit
/// test (`club_sdk_2/.../network_status_callbacks_test.dart`). This test
/// exercises the complementary, binding-friendly direction end-to-end: a
/// returned HTTP response (even an error one) proves the server is reachable
/// and must call `markOnline()`, recovering from a prior failure state.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'Issue 729: an SDK response recovers the network monitor to "online"',
    () async {
      final container = ProviderContainer(
        overrides: [
          serverConfigProvider.overrideWithValue(
            const ServerConfig(baseUrl: 'http://localhost:1/v1'),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Drive the monitor into a failure state first: the stubbed /health
      // probe returns 400 (≠ 200) → serverUnavailable.
      container.read(networkStatusProvider.notifier).checkNow();
      await _pumpUntil(
        () => container.read(networkStatusProvider) != NetworkStatus.online,
      );
      expect(
        container.read(networkStatusProvider),
        isNot(NetworkStatus.online),
      );

      // Any SDK request now gets a (stubbed 400) HTTP response. Receiving a
      // response proves the server is reachable → onServerReachable →
      // markOnline → back to online.
      final client = await container.read(clientProvider.future);
      await expectLater(client.users.getUsers(), throwsA(isA<Object>()));

      expect(container.read(networkStatusProvider), NetworkStatus.online);
    },
  );

  test(
    'Issue 729: a failing SDK request with an HTTP response leaves the '
    'monitor "online" (no false network-failure trigger)',
    () async {
      final container = ProviderContainer(
        overrides: [
          serverConfigProvider.overrideWithValue(
            const ServerConfig(baseUrl: 'http://localhost:1/v1'),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(networkStatusProvider), NetworkStatus.online);

      // Under the test binding every request resolves to a (stubbed 400) HTTP
      // response — i.e. an ordinary application error, not a connection drop.
      // Such an error must NOT move the monitor off "online".
      final client = await container.read(clientProvider.future);
      await expectLater(client.users.getUsers(), throwsA(isA<Object>()));

      // Give any (incorrectly) scheduled health probe a chance to run; the
      // state must remain online throughout.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(container.read(networkStatusProvider), NetworkStatus.online);
    },
  );
}

/// Polls [condition] up to [timeout], yielding to the event loop between
/// checks so pending async work (the health probe) can complete.
Future<void> _pumpUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Condition not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}
