import 'dart:async';
import 'dart:convert';

import 'package:cl_member_auth/src/models/auth_session.dart' show AuthSession;
import 'package:cl_server_config/cl_server_config.dart'
    show networkStatusProvider, serverConfigProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:club_sdk_2/remote_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../utils/session_guard_store.dart';
import 'api_http_client.dart';
import 'auth.dart';
import 'token_expiry.dart';
import 'token_storage.dart';

/// Single source of truth for the authenticated [SecureClient].
///
/// On build:
/// 1. Reads the saved [AuthSession] from [TokenStorage].
/// 2. Constructs a [SecureClient] via `createRemoteSecureClient(...)`,
///    pre-authenticated with the saved access token if one exists.
/// 3. Wires up [RemoteStore.onTokenExpired] so that 401 responses
///    automatically attempt a token refresh before failing.
///
/// After login/logout, the `AuthNotifier` invalidates this provider so it
/// rebuilds with the current session from [TokenStorage]. This ensures all
/// downstream providers that watch `clientProvider` receive a fresh client
/// whose auth token matches the persisted session.
final clientProvider = AsyncNotifierProvider<ClientNotifier, SecureClient>(
  ClientNotifier.new,
);

class ClientNotifier extends AsyncNotifier<SecureClient> {
  /// Set once this client has ended a refused session, so a burst of 401s
  /// signs out once.
  bool sessionEnded = false;

  @override
  Future<SecureClient> build() async {
    sessionEnded = false;
    final config = ref.watch(serverConfigProvider);
    final storage = ref.read(tokenStorageProvider);
    final session = await storage.read();

    final token = (session != null && !session.isExpired)
        ? session.accessToken
        : null;

    if (session != null && session.isExpired) {
      // Drop the stale session so a future read does not try to use it.
      await storage.clear();
    }

    // Captured once so the callbacks stay valid for the lifetime of this
    // store, even across `clientProvider` rebuilds: the network monitor is a
    // separate, app-scoped provider that is not disposed when this notifier
    // rebuilds on login/logout.
    final networkStatus = ref.read(networkStatusProvider.notifier);
    final httpClient = ref.read(apiHttpClientProvider);

    final store = SessionGuardStore(
      baseUrl: config.baseUrl,
      client: httpClient,
      onSessionRefused: () => endRefusedSession(storage),
      onTokenExpired: () => _refreshToken(config.baseUrl, storage, httpClient),
      // Wire every SDK request — across all master providers — to the reactive
      // network monitor at this single chokepoint (issue #729).
      onServerReachable: networkStatus.markOnline,
      onServerUnreachable: networkStatus.checkNow,
    );

    return createRemoteSecureClient(
      baseUrl: config.baseUrl,
      authToken: token,
      store: store,
    );
  }

  /// Attempts to refresh the access token using the stored refresh token.
  ///
  /// Uses a direct HTTP call (not through [RemoteStore]) to avoid infinite
  /// retry recursion when the refresh endpoint itself returns 401.
  /// Returns the new access token on success, or `null` to let the original
  /// 401 propagate.
  ///
  /// When the server refuses to renew the session — no refresh token is
  /// stored, or `/auth/refresh` answers 401 — the session is over:
  /// [endSession] signs out, so the app goes back to login instead of
  /// showing 401s everywhere (club_core#125). A network failure is not a
  /// refusal and leaves the session alone.
  Future<String?> _refreshToken(
    String baseUrl,
    TokenStorage storage,
    http.Client? httpClient,
  ) async {
    final session = await storage.read();
    final refreshTkn = session?.refreshToken;
    if (refreshTkn == null) {
      if (session != null) await endSession(storage);
      return null;
    }

    try {
      final uri = Uri.parse('$baseUrl/auth/refresh');
      final response = await (httpClient?.post ?? http.post)(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'refreshToken': refreshTkn}),
      );
      if (response.statusCode == 401) {
        await endSession(storage);
        return null;
      }
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final newToken = AuthToken.fromMap(data);

      await storage.write(
        AuthSession(
          accessToken: newToken.accessToken,
          expiresAtUtc: newToken.expiresAtUtc,
          refreshToken: newToken.refreshToken,
        ),
      );
      ref.read(tokenExpiryProvider.notifier).state = newToken.expiresAtUtc;

      return newToken.accessToken;
    } on Object catch (_) {
      return null;
    }
  }

  /// Ends the session when the server refuses it outright — the member has
  /// left, been blocked or been deleted (club_core#157) — but only while
  /// someone is signed in. A refusal while signing in or restoring a
  /// session belongs to [AuthNotifier], which reports it.
  void endRefusedSession(TokenStorage storage) {
    if (ref.read(authStateProvider).valueOrNull == null) return;
    unawaited(endSession(storage));
  }

  /// Ends a session the server will no longer renew: clears it and, once
  /// the current call has unwound, invalidates [authStateProvider]. Its
  /// rebuild signs in again from saved credentials if there are any, and
  /// otherwise yields null, which the router answers with the login screen.
  /// Invalidating after the call, not inside it, keeps the auth rebuild from
  /// re-entering this client mid-request.
  Future<void> endSession(TokenStorage storage) async {
    if (sessionEnded) return;
    sessionEnded = true;
    await storage.clear();
    ref.read(tokenExpiryProvider.notifier).state = null;
    unawaited(Future.microtask(() => ref.invalidate(authStateProvider)));
  }
}
