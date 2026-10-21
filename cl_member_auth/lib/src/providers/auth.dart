import 'dart:developer' as developer;

import 'package:cl_server_config/cl_server_config.dart'
    show NetworkStatus, networkStatusProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_session.dart';
import 'client.dart';
import 'credential_storage.dart';
import 'token_expiry.dart';
import 'token_storage.dart';

/// Single source of truth for the currently logged-in user.
///
/// `null`             → not logged in (show login form)
/// `UserPrivate`      → logged in (show dashboard)
/// `AsyncError`       → either a status blocker (pending/blocked/left), a
///                       [SessionRestoreUnreachable] while the stored
///                       session cannot be checked, or a transient error to
///                       surface in the UI.
final authStateProvider = AsyncNotifierProvider<AuthNotifier, UserPrivate?>(
  AuthNotifier.new,
);

/// The stored session could not be restored because the server could not
/// be reached; [error] is what the request failed with. The token and the
/// saved credentials are kept, and the restore runs again once the network
/// monitor sees the server back (#192).
class SessionRestoreUnreachable implements Exception {
  const SessionRestoreUnreachable(this.error);

  /// The network failure or 5xx answer behind it.
  final Object error;

  @override
  String toString() => 'SessionRestoreUnreachable: $error';
}

class AuthNotifier extends AsyncNotifier<UserPrivate?> {
  TokenStorage get storage => ref.read(tokenStorageProvider);
  CredentialStorage get credentials => ref.read(credentialStorageProvider);

  /// Whether the last [login] saved the credentials for auto-login. False
  /// when this device cannot store them, e.g. a browser on a plain-http
  /// page, which has no WebCrypto (#146): the member is signed in, and
  /// will sign in again next time.
  bool get credentialsSaved => _credentialsSaved;
  bool _credentialsSaved = true;

  @override
  Future<UserPrivate?> build() async {
    // A restore that could not reach the server tries again as soon as the
    // network monitor sees the server back (#192).
    ref.listen<NetworkStatus>(networkStatusProvider, (previous, next) {
      if (next == NetworkStatus.online &&
          previous != NetworkStatus.online &&
          state.error is SessionRestoreUnreachable) {
        ref.invalidateSelf();
      }
    });
    return restoreFromStoredSession();
  }

  /// Signs in again from what this device stored: the session token, else
  /// the saved credentials.
  ///
  /// Only the server's refusal clears what is stored. When the server
  /// cannot be reached (no response, or a 5xx) the token and the saved
  /// credentials are kept and the restore fails with
  /// [SessionRestoreUnreachable]; it runs again once the server is back
  /// (#192). A refused account (blocked, left, not found) clears everything
  /// and is rethrown so the login view explains it.
  Future<UserPrivate?> restoreFromStoredSession() async {
    final session = await storage.read();

    // Valid token: try using it directly.
    if (session != null && !session.isExpired) {
      final client = await ref.read(clientProvider.future);
      try {
        final user = await client.auth.getCurrentUser();
        checkStatus(user);
        ref.read(tokenExpiryProvider.notifier).state = session.expiresAtUtc;
        return user;
      } on Exception catch (e) {
        if (unreachable(e)) throw _unreachableRestore(e);
        if (e is SdkException && accountRefusalCodes.contains(e.code)) {
          await _clearAll();
          rethrow;
        }
        // Token rejected: fall through to credential-based re-login.
      }
    }

    // Token missing, expired or rejected: try re-login with saved
    // credentials.
    if (session != null) {
      await storage.clear();
      ref.invalidate(clientProvider);
    }

    final SavedCredential? saved;
    try {
      saved = await credentials.read();
    } on Object catch (error) {
      // Stored credentials this device cannot read (#146) are as good as
      // none.
      developer.log(
        'Could not read the saved credentials',
        name: 'cl_member_auth',
        error: error,
      );
      return null;
    }
    if (saved == null) return null;

    try {
      return await _loginWithCredentials(saved.username, saved.password);
    } on Exception catch (e) {
      if (unreachable(e)) throw _unreachableRestore(e);
      // The server refused the saved credentials: clear everything. A
      // refused account is reported; anything else shows the login form.
      await _clearAll();
      if (e is SdkException && accountRefusalCodes.contains(e.code)) rethrow;
      return null;
    }
  }

  /// Codes that refuse the account itself, not just the token or password.
  static const Set<String> accountRefusalCodes = {
    SdkErrorCode.accountBlocked,
    SdkErrorCode.userNotFound,
    SdkErrorCode.accountLeft,
  };

  /// Whether [error] says the server could not be reached rather than that
  /// it refused: a failure with no response, or a 5xx answer.
  static bool unreachable(Object error) => switch (error) {
    ServerException(:final statusCode) => statusCode >= 500,
    SdkException() => false,
    _ => true,
  };

  SessionRestoreUnreachable _unreachableRestore(Object error) {
    // A 5xx answer reaches no network callback; ask the monitor to look, so
    // the network-failure screen and its retry follow the server.
    ref.read(networkStatusProvider.notifier).checkNow();
    return SessionRestoreUnreachable(error);
  }

  Future<void> login(String username, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await _loginWithCredentials(username, password);
      // Persist credentials for auto-login on next app start. The server's
      // answer alone decides the sign-in: a save that fails is reported
      // through [credentialsSaved], never as a failed sign-in (#146).
      _credentialsSaved = await _saveCredentials(username, password);
      return user;
    });
  }

  Future<bool> _saveCredentials(String username, String password) async {
    try {
      await credentials.write(username: username, password: password);
      return true;
    } on Object catch (error) {
      developer.log(
        'Could not save the credentials for auto-login',
        name: 'cl_member_auth',
        error: error,
      );
      return false;
    }
  }

  Future<void> logout() async {
    final client = await ref.read(clientProvider.future);
    try {
      await client.auth.logout();
    } on Object catch (_) {
      // Even if the server call fails, clear local state.
    }
    await _clearAll();
    state = const AsyncData(null);
  }

  /// Performs a full login flow: authenticate, persist the session token,
  /// rebuild [clientProvider], and fetch the user profile.
  Future<UserPrivate> _loginWithCredentials(
    String username,
    String password,
  ) async {
    final client = await ref.read(clientProvider.future);
    final token = await client.auth.login(username, password);
    await storage.write(
      AuthSession(
        accessToken: token.accessToken,
        expiresAtUtc: token.expiresAtUtc,
        refreshToken: token.refreshToken,
      ),
    );
    ref.read(tokenExpiryProvider.notifier).state = token.expiresAtUtc;
    // Rebuild clientProvider so downstream providers get an authenticated
    // client.
    ref.invalidate(clientProvider);
    final freshClient = await ref.read(clientProvider.future);
    final user = await freshClient.auth.getCurrentUser();
    checkStatus(user);
    return user;
  }

  /// Clears all persisted auth state: token session, saved credentials, and
  /// the cached client.
  Future<void> _clearAll() async {
    await storage.clear();
    await credentials.clear();
    ref.read(tokenExpiryProvider.notifier).state = null;
    ref.invalidate(clientProvider);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final client = await ref.read(clientProvider.future);
    await client.auth.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  /// Requests a password reset for [email].
  ///
  /// The server always responds the same way regardless of whether the email
  /// matches a member (it never reveals account existence), so callers must
  /// surface a speculative confirmation rather than branching on the result.
  Future<void> resetPassword(String email) async {
    final client = await ref.read(clientProvider.future);
    await client.auth.resetPassword(email);
  }

  /// Soft-deletes the currently logged-in user, then logs them out.
  Future<void> deleteSelf() async {
    final user = state.valueOrNull;
    if (user == null) return;
    final client = await ref.read(clientProvider.future);
    await client.users.deleteUser(user.username);
    await logout();
  }

  bool get isLoggedIn => state.valueOrNull != null;

  bool get isAdmin {
    final u = state.valueOrNull;
    if (u == null) return false;
    return u.roles.isAdmin || u.isSuperAdmin;
  }

  bool get isSuperAdmin => state.valueOrNull?.isSuperAdmin ?? false;
  bool get isCoach => state.valueOrNull?.roles.isCoach ?? false;

  /// Replace the cached `UserPrivate` without round-tripping the server.
  ///
  /// Used by callers that already received an updated user (e.g.,
  /// `users.submitForReview()` returns the new `UserPrivate` directly).
  /// Keeps `authStateProvider` in sync so router redirects re-evaluate.
  void setUser(UserPrivate user) {
    state = AsyncData(user);
  }

  void checkStatus(UserPrivate user) {
    switch (user.status) {
      case UserStatus.blocked:
        throw SdkError(
          'Account is blocked: ${user.username}',
          code: SdkErrorCode.accountBlocked,
        );
      case UserStatus.left:
        throw SdkError(
          'Account has left: ${user.username}',
          code: SdkErrorCode.accountLeft,
        );
      case UserStatus.registered:
      case UserStatus.pending:
      case UserStatus.active:
        // Allowed through — the host router inspects status and routes
        // `registered` and `pending` users to the appropriate destination.
        return;
    }
  }
}
