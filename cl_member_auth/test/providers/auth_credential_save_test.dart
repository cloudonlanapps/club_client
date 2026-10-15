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

/// Credential storage of a browser without WebCrypto (a plain-http page
/// on a LAN address): what it holds cannot be read, and nothing can be
/// written.
class _NoWebCrypto implements CredentialStorage {
  @override
  Future<SavedCredential?> read() async =>
      throw StateError('crypto.subtle is undefined');
  @override
  Future<void> write({
    required String username,
    required String password,
  }) async => throw StateError('crypto.subtle is undefined');
  @override
  Future<void> clear() async {}
}

class _Credentials implements CredentialStorage {
  SavedCredential? saved;
  @override
  Future<SavedCredential?> read() async => saved;
  @override
  Future<void> write({
    required String username,
    required String password,
  }) async => saved = SavedCredential(
    username: username,
    password: password,
    savedAtUtc: DateTime.now().toUtc(),
  );
  @override
  Future<void> clear() async => saved = null;
}

final _me = UserPrivate(
  username: 'asha',
  displayName: 'Asha',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(),
  createdAtUtc: DateTime.utc(2024),
);

http.Response _json(int status, Object body) => http.Response(
  json.encode(body),
  status,
  headers: {'content-type': 'application/json'},
);

/// Accepts any sign-in and answers `/auth/me` with [_me].
Future<http.Response> _server(http.Request request) async {
  if (request.url.path.endsWith('/auth/login')) {
    return _json(200, {
      'accessToken': 'access',
      'tokenType': 'bearer',
      'expiresAtUtc': DateTime.now()
          .toUtc()
          .add(const Duration(hours: 1))
          .millisecondsSinceEpoch,
      'refreshToken': 'refresh',
    });
  }
  if (request.url.path.endsWith('/auth/me')) return _json(200, _me.toMap());
  return _json(200, <String, dynamic>{});
}

ProviderContainer _container(_Tokens tokens, CredentialStorage credentials) {
  final container = ProviderContainer(
    overrides: [
      serverConfigProvider.overrideWithValue(
        const ServerConfig(baseUrl: 'http://api.test/v1'),
      ),
      tokenStorageProvider.overrideWithValue(tokens),
      credentialStorageProvider.overrideWithValue(credentials),
      apiHttpClientProvider.overrideWithValue(MockClient(_server)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Issue 146: saving the credentials is apart from signing in', () {
    test('Issue 146: a sign-in the server accepts signs in, although the '
        'credentials cannot be saved', () async {
      final tokens = _Tokens();
      final container = _container(tokens, _NoWebCrypto());
      expect(await container.read(authStateProvider.future), isNull);

      final auth = container.read(authStateProvider.notifier);
      await auth.login('asha', 'secret');

      final state = container.read(authStateProvider);
      expect(state.hasError, isFalse);
      expect(state.valueOrNull?.username, 'asha');
      expect(tokens.session?.accessToken, 'access');
      expect(auth.credentialsSaved, isFalse);
    });

    test('Issue 146: credentials that are saved say so', () async {
      final credentials = _Credentials();
      final container = _container(_Tokens(), credentials);
      await container.read(authStateProvider.future);

      final auth = container.read(authStateProvider.notifier);
      await auth.login('asha', 'secret');

      expect(container.read(authStateProvider).valueOrNull?.username, 'asha');
      expect(credentials.saved?.username, 'asha');
      expect(auth.credentialsSaved, isTrue);
    });

    test('Issue 146: credentials that cannot be read start the app signed '
        'out, not in an error', () async {
      final container = _container(_Tokens(), _NoWebCrypto());

      expect(await container.read(authStateProvider.future), isNull);
      expect(container.read(authStateProvider).hasError, isFalse);
    });
  });
}
