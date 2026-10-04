import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_session.dart';

/// Provides a [TokenStorage] instance.
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return const TokenStorage();
});

/// Persists the [AuthSession] across app restarts via `shared_preferences`.
///
/// Stored as a single JSON string under a fixed key. Storing the opaque access
/// token (not the password) keeps the data slightly safer than legacy
/// approaches.
class TokenStorage {
  const TokenStorage();

  static const _key = 'cl_member_auth.session';

  Future<AuthSession?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AuthSession.fromJson(raw);
    } on Object catch (_) {
      // Corrupt entry — purge it.
      await prefs.remove(_key);
      return null;
    }
  }

  Future<void> write(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, session.toJson());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
