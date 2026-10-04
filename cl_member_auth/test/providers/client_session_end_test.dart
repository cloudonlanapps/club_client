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

final _me = UserPrivate(
  username: 'session_member',
  displayName: 'Session Member',
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

http.Response _unauthorized(String code) => _json(401, {
  'detail': {'code': code, 'message': 'Invalid or expired token'},
});

/// A server whose tokens are good until [expired], after which every call
/// is a 401 and `/auth/refresh` does what [refresh] says. While [refusal]
/// is set, every call but a refresh is a 401 with that code instead: the
/// session is refused outright, with no refresh attempted.
class _Server {
  bool expired = false;
  String? refusal;

  /// When set, a lookup of any member under `/users/` is a 404
  /// `USER_NOT_FOUND`: a missing member, not a refused session.
  bool missingUsers = false;
  Future<http.Response> Function() refresh = () async =>
      _unauthorized('INVALID_REFRESH_TOKEN');

  Future<http.Response> handle(http.Request request) async {
    if (request.url.path.endsWith('/auth/refresh')) return refresh();
    final refused = refusal;
    if (refused != null) return _unauthorized(refused);
    if (expired) return _unauthorized('INVALID_TOKEN');
    if (missingUsers && request.url.path.contains('/users/')) {
      return _json(404, {
        'detail': {'code': 'USER_NOT_FOUND', 'message': 'User not found'},
      });
    }
    if (request.url.path.endsWith('/auth/me')) return _json(200, _me.toMap());
    return _json(200, <String, dynamic>{});
  }
}

Future<void> _drain() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> scenario(
    _Server server,
    Future<void> Function(ProviderContainer c, _Tokens tokens) body,
  ) async {
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
        apiHttpClientProvider.overrideWithValue(MockClient(server.handle)),
      ],
    );
    addTearDown(container.dispose);
    // Signed in from the stored session.
    expect(
      (await container.read(authStateProvider.future))?.username,
      'session_member',
    );
    await body(container, tokens);
  }

  group('Issue 125: a session the server will not renew ends', () {
    test('Issue 125: a refused refresh signs out, back to login', () async {
      final server = _Server();
      await scenario(server, (container, tokens) async {
        server.expired = true;
        final client = await container.read(clientProvider.future);

        await expectLater(
          client.auth.getCurrentUser(),
          throwsA(isA<ServerException>()),
        );
        await _drain();

        expect(tokens.session, isNull, reason: 'the dead session is cleared');
        expect(
          await container.read(authStateProvider.future),
          isNull,
          reason: 'signed out, so the router shows the login screen',
        );
      });
    });

    test('Issue 125: a network failure on refresh keeps the session', () async {
      final server = _Server()
        ..refresh = () async => throw http.ClientException('offline');
      await scenario(server, (container, tokens) async {
        server.expired = true;
        final client = await container.read(clientProvider.future);

        await expectLater(
          client.auth.getCurrentUser(),
          throwsA(isA<Object>()),
        );
        await _drain();

        expect(tokens.session, isNotNull);
        expect(
          container.read(authStateProvider).valueOrNull?.username,
          'session_member',
        );
      });
    });
  });

  group('Issue 157: a session refused outright ends', () {
    for (final code in ['ACCOUNT_LEFT', 'USER_NOT_FOUND', 'ACCOUNT_BLOCKED']) {
      test('Issue 157: a request refused with $code signs out', () async {
        final server = _Server();
        await scenario(server, (container, tokens) async {
          server.refusal = code;
          final client = await container.read(clientProvider.future);

          await expectLater(
            client.users.getUsers(),
            throwsA(isA<ServerException>()),
          );
          await _drain();

          expect(tokens.session, isNull, reason: 'the dead session is cleared');
          expect(
            await container.read(authStateProvider.future),
            isNull,
            reason: 'signed out, so the router shows the login screen',
          );
        });
      });
    }

    for (final code in ['ACCOUNT_LEFT', 'USER_NOT_FOUND']) {
      test('Issue 157: a refresh refused with $code signs out', () async {
        final server = _Server()..refresh = () async => _unauthorized(code);
        await scenario(server, (container, tokens) async {
          server.expired = true;
          final client = await container.read(clientProvider.future);

          await expectLater(
            client.auth.getCurrentUser(),
            throwsA(isA<ServerException>()),
          );
          await _drain();

          expect(tokens.session, isNull);
          expect(await container.read(authStateProvider.future), isNull);
        });
      });
    }

    test('Issue 157: a 404 USER_NOT_FOUND about another member keeps the '
        'session', () async {
      final server = _Server();
      await scenario(server, (container, tokens) async {
        server.missingUsers = true;
        final client = await container.read(clientProvider.future);

        await expectLater(
          client.users.getUserPrivate('someone_else'),
          throwsA(isA<ServerException>()),
        );
        await _drain();

        expect(tokens.session, isNotNull);
        expect(
          container.read(authStateProvider).valueOrNull?.username,
          'session_member',
        );
      });
    });
  });
}
