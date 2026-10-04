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
/// `AsyncError`       → either a status blocker (pending/blocked/left) or a
///                       transient error to surface in the UI.
final authStateProvider = AsyncNotifierProvider<AuthNotifier, UserPrivate?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<UserPrivate?> {
  TokenStorage get storage => ref.read(tokenStorageProvider);
  CredentialStorage get credentials => ref.read(credentialStorageProvider);

  @override
  Future<UserPrivate?> build() async {
    return restoreFromStoredSession();
  }

  Future<UserPrivate?> restoreFromStoredSession() async {
    final session = await storage.read();

    // Valid token — try using it directly.
    if (session != null && !session.isExpired) {
      final client = await ref.read(clientProvider.future);
      try {
        final user = await client.auth.getCurrentUser();
        checkStatus(user);
        ref.read(tokenExpiryProvider.notifier).state = session.expiresAtUtc;
        return user;
      } on SdkException catch (e) {
        if (e.code == SdkErrorCode.accountBlocked ||
            e.code == SdkErrorCode.userNotFound ||
            e.code == SdkErrorCode.accountLeft) {
          await _clearAll();
          rethrow;
        }
        // Token rejected — fall through to credential-based re-login.
      } on Object catch (_) {
        // Token rejected — fall through to credential-based re-login.
      }
    }

    // Token missing or expired — try re-login with saved credentials.
    if (session != null) {
      await storage.clear();
      ref.invalidate(clientProvider);
    }

    final saved = await credentials.read();
    if (saved == null) return null;

    try {
      return await _loginWithCredentials(saved.username, saved.password);
    } on Object catch (_) {
      // Re-login failed — clear everything and show login screen.
      await _clearAll();
      return null;
    }
  }

  Future<void> login(String username, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await _loginWithCredentials(username, password);
      // Persist credentials for auto-login on next app start.
      await credentials.write(username: username, password: password);
      return user;
    });
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
