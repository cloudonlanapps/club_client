import 'package:cl_remote_store/cl_remote_store.dart';
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
}
