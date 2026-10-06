import 'dart:convert';
import 'dart:io';

import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:cl_remote_store/src/providers/sessionless_client.dart';
import 'package:cl_server_config/cl_server_config.dart'
    show ServerConfig, serverConfigProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

class _FakeCapabilities extends Fake implements CapabilitiesSource {
  _FakeCapabilities(this.answer);

  final Capabilities answer;
  int calls = 0;

  @override
  Future<Capabilities> getCapabilities() async {
    calls += 1;
    return answer;
  }
}

ProviderContainer _container(CapabilitiesSource source) {
  final container = ProviderContainer(
    overrides: [
      secureClientProvider.overrideWith(
        (ref) async => fakeSecureClient(capabilities: source),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('Issue 84: capabilities', () {
    test('identityVerificationProvider is null until the server answers', () {
      final container = _container(
        _FakeCapabilities(
          const Capabilities(creditSystem: false, identityVerification: false),
        ),
      );

      expect(container.read(identityVerificationProvider), isNull);
    });

    test('identityVerificationProvider reports the server off', () async {
      final container = _container(
        _FakeCapabilities(
          const Capabilities(creditSystem: false, identityVerification: false),
        ),
      );

      await container.read(capabilitiesProvider.future);

      expect(container.read(identityVerificationProvider), isFalse);
    });

    test('identityVerificationProvider reports the server on', () async {
      final container = _container(
        _FakeCapabilities(const Capabilities(creditSystem: false)),
      );

      await container.read(capabilitiesProvider.future);

      expect(container.read(identityVerificationProvider), isTrue);
    });

    test('the capabilities are read once and shared', () async {
      final source = _FakeCapabilities(const Capabilities(creditSystem: true));
      final container = _container(source);

      await container.read(capabilitiesProvider.future);
      await container.read(capabilitiesProvider.future);
      container.read(identityVerificationProvider);

      expect(source.calls, 1);
    });
  });

  group('Issue 31: defaultCountryCodeProvider', () {
    test('Issue 31: gives the code the server reports', () async {
      final container = _container(
        _FakeCapabilities(
          const Capabilities(creditSystem: false, defaultCountryCode: '44'),
        ),
      );

      await container.read(capabilitiesProvider.future);

      expect(container.read(defaultCountryCodeProvider), '44');
    });

    test('Issue 31: gives 91 when the server reports none', () async {
      final container = _container(
        _FakeCapabilities(const Capabilities(creditSystem: false)),
      );

      await container.read(capabilitiesProvider.future);

      expect(fallbackCountryCode, '91');
      expect(container.read(defaultCountryCodeProvider), fallbackCountryCode);
    });

    test('Issue 31: gives 91 until the server answers', () {
      final container = _container(
        _FakeCapabilities(
          const Capabilities(creditSystem: false, defaultCountryCode: '44'),
        ),
      );

      expect(container.read(defaultCountryCodeProvider), fallbackCountryCode);
    });
  });

  group('Issue 31: capabilities without a session client (the website)', () {
    test('Issue 31: read through the sessionless client when the host '
        'gave no secureClientProvider', () async {
      final source = _FakeCapabilities(
        const Capabilities(creditSystem: false, defaultCountryCode: '44'),
      );
      final container = ProviderContainer(
        overrides: [
          clSessionlessClientProvider.overrideWith(
            (ref) async => fakeSecureClient(capabilities: source),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(defaultCountryCodeProvider), fallbackCountryCode);
      await container.read(capabilitiesProvider.future);

      expect(container.read(defaultCountryCodeProvider), '44');
      expect(source.calls, 1);
    });

    test('Issue 31: one unauthenticated GET /capabilities at the API base '
        'gives the code the server reports', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final requests = <String>[];
      server.listen((request) async {
        final authorization = request.headers.value(
          HttpHeaders.authorizationHeader,
        );
        requests.add('${request.method} ${request.uri.path} $authorization');
        request.response
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'creditSystem': false,
              'evaluations': false,
              'eventMarketing': false,
              'identityVerification': false,
              'defaultCountryCode': '44',
            }),
          );
        await request.response.close();
      });
      final container = ProviderContainer(
        overrides: [
          serverConfigProvider.overrideWithValue(
            ServerConfig(baseUrl: 'http://127.0.0.1:${server.port}/v1'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(capabilitiesProvider.future);

      expect(container.read(defaultCountryCodeProvider), '44');
      expect(requests, ['GET /v1/capabilities null']);
    });

    test(
      'Issue 31: the session client is used when the host gave one',
      () async {
        final session = _FakeCapabilities(
          const Capabilities(creditSystem: false, defaultCountryCode: '44'),
        );
        final sessionless = _FakeCapabilities(
          const Capabilities(creditSystem: false, defaultCountryCode: '1'),
        );
        final container = ProviderContainer(
          overrides: [
            secureClientProvider.overrideWith(
              (ref) async => fakeSecureClient(capabilities: session),
            ),
            clSessionlessClientProvider.overrideWith(
              (ref) async => fakeSecureClient(capabilities: sessionless),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container.read(capabilitiesProvider.future);

        expect(container.read(defaultCountryCodeProvider), '44');
        expect(sessionless.calls, 0);
      },
    );

    test('Issue 31: a session client that fails is not replaced by the '
        'sessionless one', () async {
      final sessionless = _FakeCapabilities(
        const Capabilities(creditSystem: false, defaultCountryCode: '1'),
      );
      final container = ProviderContainer(
        overrides: [
          secureClientProvider.overrideWith(
            (ref) async => throw StateError('no client'),
          ),
          clSessionlessClientProvider.overrideWith(
            (ref) async => fakeSecureClient(capabilities: sessionless),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(capabilitiesProvider.future),
        throwsStateError,
      );
      expect(sessionless.calls, 0);
    });
  });
}
