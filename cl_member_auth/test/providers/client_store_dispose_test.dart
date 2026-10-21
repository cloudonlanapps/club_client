import 'dart:convert';

import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_auth/src/providers/credential_storage.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Tokens implements TokenStorage {
  AuthSession? session;
  @override
  Future<AuthSession?> read() async => session;
  @override
  Future<void> write(AuthSession value) async => session = value;
  @override
  Future<void> clear() async => session = null;
}

class _NoCredentials implements CredentialStorage {
  @override
  Future<SavedCredential?> read() async => null;
  @override
  Future<void> write({
    required String username,
    required String password,
  }) async {}
  @override
  Future<void> clear() async {}
}

/// A shared fake that records whether anyone closed it.
class _TrackedClient extends MockClient {
  _TrackedClient(super.fn);
  bool closed = false;
  @override
  void close() {
    closed = true;
    super.close();
  }
}

final _me = UserPrivate(
  username: 'session_member',
  displayName: 'Session Member',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(),
  createdAtUtc: DateTime.utc(2024),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Issue 190: a rebuild of clientProvider disposes the store it replaces '
    'and leaves the shared HTTP client open',
    () async {
      final shared = _TrackedClient(
        (request) async => http.Response(
          json.encode(_me.toMap()),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      final tokens = _Tokens()
        ..session = AuthSession(
          accessToken: 'access',
          expiresAtUtc: DateTime.now().toUtc().add(const Duration(hours: 1)),
          refreshToken: 'refresh',
        );
      final container = ProviderContainer(
        overrides: [
          serverConfigProvider.overrideWithValue(
            const ServerConfig(baseUrl: 'http://api.test/v1'),
          ),
          tokenStorageProvider.overrideWithValue(tokens),
          credentialStorageProvider.overrideWithValue(_NoCredentials()),
          apiHttpClientProvider.overrideWithValue(shared),
        ],
      );
      addTearDown(container.dispose);

      await container.read(clientProvider.future);
      final first = container.read(clientProvider.notifier).store;
      expect(first, isNotNull);
      expect(first!.isDisposed, isFalse);

      container.invalidate(clientProvider);
      final client = await container.read(clientProvider.future);
      final second = container.read(clientProvider.notifier).store;

      expect(first.isDisposed, isTrue, reason: 'the replaced store is freed');
      expect(identical(first, second), isFalse);
      expect(second!.isDisposed, isFalse);
      expect(shared.closed, isFalse, reason: 'the shared client is the caller');
      expect(
        (await client.auth.getCurrentUser()).username,
        'session_member',
        reason: 'the new store still serves requests on the shared client',
      );
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
