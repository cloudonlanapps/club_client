import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Provides a [CredentialStorage] instance.
final credentialStorageProvider = Provider<CredentialStorage>((ref) {
  return const CredentialStorage();
});

/// Securely persists login credentials (username + password) so the app can
/// re-authenticate automatically when the access token expires.
///
/// Credentials are encrypted at rest via `flutter_secure_storage` (Keychain on
/// iOS, EncryptedSharedPreferences on Android). A `savedAtUtc` timestamp is
/// stored alongside; if the credentials are older than 3 days they
/// are silently deleted on the next read.
///
/// Cleared explicitly on logout or automatically when expired.
class CredentialStorage {
  const CredentialStorage();

  static const _key = 'cl_member_auth.credentials';
  static const maxAge = Duration(days: 3);

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    mOptions: MacOsOptions(useDataProtectionKeyChain: false),
  );

  Future<SavedCredential?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) return null;

    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      final credential = SavedCredential.fromMap(map);

      if (credential.isExpired) {
        await clear();
        return null;
      }

      return credential;
    } on Object catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> write({
    required String username,
    required String password,
  }) async {
    final credential = SavedCredential(
      username: username,
      password: password,
      savedAtUtc: DateTime.now().toUtc(),
    );
    await _storage.write(key: _key, value: credential.toJson());
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}

/// Stored credential with a timestamp for expiry checking.
class SavedCredential {
  const SavedCredential({
    required this.username,
    required this.password,
    required this.savedAtUtc,
  });

  factory SavedCredential.fromMap(Map<String, dynamic> map) {
    return SavedCredential(
      username: map['username'] as String? ?? '',
      password: map['password'] as String? ?? '',
      savedAtUtc: DateTime.fromMillisecondsSinceEpoch(
        map['savedAtUtc'] as int? ?? 0,
        isUtc: true,
      ),
    );
  }

  final String username;
  final String password;
  final DateTime savedAtUtc;

  bool get isExpired =>
      DateTime.now().toUtc().difference(savedAtUtc) > CredentialStorage.maxAge;

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'savedAtUtc': savedAtUtc.millisecondsSinceEpoch,
    };
  }

  String toJson() => json.encode(toMap());
}
