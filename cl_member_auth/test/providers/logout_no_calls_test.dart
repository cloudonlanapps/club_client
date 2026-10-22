import 'dart:async';
import 'dart:convert';

import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_auth/src/providers/credential_storage.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
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

const Map<String, Object> _emptyPage = {
  'items': <Object>[],
  'total': 0,
  'limit': 20,
  'offset': 0,
};

/// A server that serves a signed-in member until `/auth/logout`, which
/// revokes the session: from then on every call is a 401, a refresh
/// included, as the real server answers a dropped token.
class _Server {
  /// Every request, as `METHOD /path`.
  final List<String> requests = [];

  /// Index into [requests] of the logout, once it has arrived.
  int? logoutAt;

  /// While set, the next `/auth/me` is held until the logout arrives, and
  /// is then answered 401: a request in flight while the member signs out.
  Completer<void>? holdMe;

  bool get revoked => logoutAt != null;

  /// What was asked after the logout, the logout itself left out.
  List<String> get afterLogout =>
      revoked ? requests.sublist(logoutAt! + 1) : const [];

  Future<http.Response> handle(http.Request request) async {
    final path = request.url.path;
    requests.add('${request.method} $path');
    if (path.endsWith('/auth/logout')) {
      logoutAt = requests.length - 1;
      final held = holdMe;
      holdMe = null;
      held?.complete();
      // The in-flight request comes back refused before the logout answers.
      await _drain();
      return _json(200, <String, dynamic>{});
    }
    if (path.endsWith('/capabilities')) {
      // Answered with or without a session (club_server#443).
      return _json(200, {
        'creditSystem': false,
        'evaluations': false,
        'eventMarketing': false,
        'identityVerification': true,
      });
    }
    if (path.endsWith('/auth/login')) {
      logoutAt = null;
      return _json(200, {
        'accessToken': 'access-2',
        'tokenType': 'bearer',
        'expiresAtUtc': DateTime.now()
            .toUtc()
            .add(const Duration(hours: 1))
            .millisecondsSinceEpoch,
        'refreshToken': 'refresh-2',
      });
    }
    if (path.endsWith('/auth/me') && holdMe != null) {
      await holdMe!.future;
    }
    if (revoked) {
      return _json(401, {
        'detail': {
          'code': path.endsWith('/auth/refresh')
              ? 'INVALID_REFRESH_TOKEN'
              : 'INVALID_TOKEN',
          'message': 'Invalid or expired token',
        },
      });
    }
    if (path.endsWith('/auth/me')) return _json(200, _me.toMap());
    if (path.endsWith('/media/user_avatar')) return _json(200, <Object>[]);
    return _json(200, _emptyPage);
  }
}

Future<void> _drain() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// A container wired as `clubMain()` wires the app, signed in from a stored
/// session.
Future<ProviderContainer> _signedIn(_Server server) async {
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
      secureClientProvider.overrideWith(
        (ref) => ref.watch(sessionClientProvider.future),
      ),
      tokenFreeClientProvider.overrideWith(
        (ref) => ref.watch(clientProvider.future),
      ),
      currentUserProvider.overrideWith(
        (ref) => ref.watch(authStateProvider).valueOrNull,
      ),
    ],
  );
  addTearDown(container.dispose);
  expect(
    (await container.read(authStateProvider.future))?.username,
    'session_member',
  );
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Issue 272: signing out stops the requests that need the session', () {
    test('Issue 272: the masters an open page watches make no request once '
        'signed out', () async {
      final server = _Server();
      final container = await _signedIn(server);
      // An open page: the venues list, the notification bell and a member's
      // avatar, each kept alive by a listener as a mounted widget does.
      container
        ..listen(clVenuesMasterProvider, (_, _) {})
        ..listen(clNotificationsMasterProvider, (_, _) {})
        ..listen(avatarImageProvider('other_member'), (_, _) {});
      await container.read(clVenuesMasterProvider.future);
      await container.read(clNotificationsMasterProvider.future);
      await container.read(avatarImageProvider('other_member').future);
      expect(server.requests, contains('GET /v1/venues'));

      await container.read(authStateProvider.notifier).logout();
      await _drain();

      expect(server.revoked, isTrue);
      expect(server.afterLogout, isEmpty);
    });

    test('Issue 272: a request refused while signing out tries no token '
        'refresh', () async {
      final server = _Server();
      final container = await _signedIn(server);
      final client = await container.read(clientProvider.future);
      server.holdMe = Completer<void>();
      final inFlight = client.auth.getCurrentUser().then<Object?>(
        (user) => user,
        onError: (Object error) => error,
      );
      await _drain();

      await container.read(authStateProvider.notifier).logout();
      await inFlight;
      await _drain();

      expect(
        server.requests.where((r) => r.endsWith('/auth/refresh')),
        isEmpty,
      );
      expect(container.read(authStateProvider).valueOrNull, isNull);
    });

    test('Issue 272: a mounted avatar does not fetch again once signed '
        'out', () async {
      final server = _Server();
      final container = await _signedIn(server);
      // What a mounted avatar watches: its link and the image headers.
      container
        ..listen(avatarImageProvider('session_member'), (_, _) {})
        ..listen(imageAuthHeadersProvider, (_, _) {});
      await container.read(avatarImageProvider('session_member').future);
      expect(
        server.requests,
        contains('GET /v1/users/by_id/session_member/media/user_avatar'),
      );

      await container.read(authStateProvider.notifier).logout();
      await _drain();

      expect(server.afterLogout, isEmpty);
      expect(await container.read(imageAuthHeadersProvider.future), isEmpty);
    });

    test('Issue 272: signing in again hands an open master the new '
        'client', () async {
      final server = _Server();
      final container = await _signedIn(server);
      container.listen(clVenuesMasterProvider, (_, _) {});
      await container.read(clVenuesMasterProvider.future);
      await container.read(authStateProvider.notifier).logout();
      await _drain();
      server.requests.clear();

      await container
          .read(authStateProvider.notifier)
          .login('session_member', 'secret');
      await container.read(clVenuesMasterProvider.future);

      expect(container.read(authStateProvider).valueOrNull, isNotNull);
      expect(server.requests, contains('GET /v1/venues'));
    });

    test('Issue 272: the capabilities are still read once signed out, for '
        'the signup screens', () async {
      final server = _Server();
      final container = await _signedIn(server);
      container.listen(capabilitiesProvider, (_, _) {});
      await container.read(capabilitiesProvider.future);

      await container.read(authStateProvider.notifier).logout();
      await _drain();

      expect(
        (await container.read(
          capabilitiesProvider.future,
        )).identityVerification,
        isTrue,
      );
      expect(server.afterLogout, everyElement('GET /v1/capabilities'));
    });
  });
}
