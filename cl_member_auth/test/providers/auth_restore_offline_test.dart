import 'dart:convert';

import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_auth/src/providers/credential_storage.dart';
import 'package:cl_server_config/cl_server_config.dart'
    show NetworkFailureScreen, NetworkStatus, networkStatusProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class _Tokens implements TokenStorage {
  AuthSession? session;
  @override
  Future<AuthSession?> read() async => session;
  @override
  Future<void> write(AuthSession value) async => session = value;
  @override
  Future<void> clear() async => session = null;
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

/// A server that is either down ([offline]: every request fails before a
/// response), answers [failStatus] to everything, refuses a sign-in with
/// [loginRefusal], or works.
class _Server {
  bool offline = true;
  int? failStatus;
  String? loginRefusal;

  Future<http.Response> handle(http.Request request) async {
    if (offline) throw http.ClientException('offline', request.url);
    final status = failStatus;
    if (status != null) {
      return _json(status, {
        'detail': {'code': 'INTERNAL_ERROR', 'message': 'down'},
      });
    }
    final path = request.url.path;
    if (path.endsWith('/auth/login')) {
      final refusal = loginRefusal;
      if (refusal != null) {
        return _json(401, {
          'detail': {'code': refusal, 'message': 'refused'},
        });
      }
      return _json(200, {
        'accessToken': 'fresh',
        'tokenType': 'bearer',
        'expiresAtUtc': DateTime.now()
            .toUtc()
            .add(const Duration(hours: 1))
            .millisecondsSinceEpoch,
        'refreshToken': 'fresh-refresh',
      });
    }
    if (path.endsWith('/auth/me')) return _json(200, _me.toMap());
    return _json(200, <String, dynamic>{});
  }
}

AuthSession _validSession() => AuthSession(
  accessToken: 'access',
  expiresAtUtc: DateTime.now().toUtc().add(const Duration(hours: 1)),
  refreshToken: 'refresh',
);

SavedCredential _saved() => SavedCredential(
  username: 'session_member',
  password: 'secret',
  savedAtUtc: DateTime.utc(2026),
);

ProviderContainer _container(
  _Server server,
  _Tokens tokens,
  _Credentials credentials,
) {
  final container = ProviderContainer(
    overrides: [
      serverConfigProvider.overrideWithValue(
        const ServerConfig(baseUrl: 'http://api.test/v1'),
      ),
      tokenStorageProvider.overrideWithValue(tokens),
      credentialStorageProvider.overrideWithValue(credentials),
      apiHttpClientProvider.overrideWithValue(MockClient(server.handle)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<Object> _restoreError(ProviderContainer container) async {
  try {
    await container.read(authStateProvider.future);
  } on Object catch (error) {
    return error;
  }
  fail('restore succeeded; expected an error');
}

Future<void> _until(bool Function() done) async {
  for (var i = 0; i < 200 && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

/// The restore's error, once the health check the failure started has
/// answered (under the test binding it fails), so the check does not
/// outlive the container.
Future<Object> _unreachableError(ProviderContainer container) async {
  final error = await _restoreError(container);
  await _until(
    () => container.read(networkStatusProvider) != NetworkStatus.online,
  );
  return error;
}

const _timeout = Timeout(Duration(seconds: 90));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Issue 192: opening the app offline keeps the session', () {
    test(
      'Issue 192: restore keeps session and credentials when the server is '
      'unreachable',
      () async {
        final server = _Server();
        final tokens = _Tokens()..session = _validSession();
        final credentials = _Credentials()..saved = _saved();
        final container = _container(server, tokens, credentials);

        final error = await _unreachableError(container);

        expect(error, isA<SessionRestoreUnreachable>());
        expect(
          (error as SessionRestoreUnreachable).error,
          isA<http.ClientException>(),
        );
        expect(tokens.session?.accessToken, 'access');
        expect(credentials.saved?.username, 'session_member');
      },
      timeout: _timeout,
    );

    test(
      'Issue 192: restore from saved credentials keeps them when the server '
      'is unreachable',
      () async {
        final server = _Server();
        final tokens = _Tokens();
        final credentials = _Credentials()..saved = _saved();
        final container = _container(server, tokens, credentials);

        final error = await _unreachableError(container);

        expect(error, isA<SessionRestoreUnreachable>());
        expect(credentials.saved?.username, 'session_member');
      },
      timeout: _timeout,
    );

    test(
      'Issue 192: a server error during restore keeps session and credentials',
      () async {
        final server = _Server()
          ..offline = false
          ..failStatus = 502;
        final tokens = _Tokens()..session = _validSession();
        final credentials = _Credentials()..saved = _saved();
        final container = _container(server, tokens, credentials);

        final error = await _unreachableError(container);

        expect(error, isA<SessionRestoreUnreachable>());
        expect(tokens.session?.accessToken, 'access');
        expect(credentials.saved?.username, 'session_member');
      },
      timeout: _timeout,
    );

    test(
      'Issue 192: the session continues once the server is reachable again',
      () async {
        final server = _Server();
        final tokens = _Tokens()..session = _validSession();
        final credentials = _Credentials()..saved = _saved();
        final container = _container(server, tokens, credentials);
        await _restoreError(container);

        // The failed request asked the monitor to check; under the test
        // binding its health probe fails, so the app is shown offline.
        await _until(
          () => container.read(networkStatusProvider) != NetworkStatus.online,
        );
        expect(
          container.read(networkStatusProvider),
          isNot(NetworkStatus.online),
        );

        server.offline = false;
        container.read(networkStatusProvider.notifier).markOnline();
        await _until(
          () => container.read(authStateProvider).valueOrNull != null,
        );

        expect(
          container.read(authStateProvider).valueOrNull?.username,
          'session_member',
        );
        expect(tokens.session?.accessToken, 'access');
      },
      timeout: _timeout,
    );
  });

  test(
    'Issue 192: restore from saved credentials reports a blocked account',
    () async {
      final server = _Server()
        ..offline = false
        ..loginRefusal = SdkErrorCode.accountBlocked;
      final tokens = _Tokens();
      final credentials = _Credentials()..saved = _saved();
      final container = _container(server, tokens, credentials);

      final error = await _restoreError(container);

      expect(error, isA<SdkException>());
      expect((error as SdkException).code, SdkErrorCode.accountBlocked);
      expect(tokens.session, isNull);
      expect(credentials.saved, isNull);
    },
    timeout: _timeout,
  );

  test(
    'Issue 192: restore from saved credentials the server refuses signs out',
    () async {
      final server = _Server()
        ..offline = false
        ..loginRefusal = 'INVALID_CREDENTIALS';
      final tokens = _Tokens();
      final credentials = _Credentials()..saved = _saved();
      final container = _container(server, tokens, credentials);

      expect(await container.read(authStateProvider.future), isNull);
      expect(credentials.saved, isNull);
    },
    timeout: _timeout,
  );

  testWidgets(
    'Issue 192: the login view shows the network-failure screen while the '
    'session cannot be restored',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authStateProvider.overrideWith(_UnreachableAuth.new)],
          child: ShadApp(
            home: Scaffold(
              body: LoginView(
                onLoginSuccess: () {},
                onNavigateToForgotPassword: () {},
                onNavigateToSignup: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(NetworkFailureScreen), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    },
    timeout: _timeout,
  );
}

class _UnreachableAuth extends AuthNotifier {
  @override
  Future<UserPrivate?> build() => Future.error(
    SessionRestoreUnreachable(http.ClientException('offline')),
  );
}
