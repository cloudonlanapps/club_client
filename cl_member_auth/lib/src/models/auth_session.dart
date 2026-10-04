import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Persisted auth session: opaque access token + UTC expiry.
///
/// Stored by `TokenStorage` in `shared_preferences` after a successful login,
/// and replayed at app startup to authenticate the `SecureClient` without
/// asking the user to log in again.
@immutable
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.expiresAtUtc,
    this.refreshToken,
  });

  factory AuthSession.fromMap(Map<String, dynamic> map) {
    return AuthSession(
      accessToken: map['accessToken'] as String? ?? '',
      expiresAtUtc: DateTime.fromMillisecondsSinceEpoch(
        map['expiresAtUtc'] as int? ?? 0,
        isUtc: true,
      ),
      refreshToken: map['refreshToken'] as String?,
    );
  }

  factory AuthSession.fromJson(String source) =>
      AuthSession.fromMap(json.decode(source) as Map<String, dynamic>);

  final String accessToken;
  final DateTime expiresAtUtc;
  final String? refreshToken;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAtUtc);

  AuthSession copyWith({
    String? accessToken,
    DateTime? expiresAtUtc,
    String? Function()? refreshToken,
  }) {
    return AuthSession(
      accessToken: accessToken ?? this.accessToken,
      expiresAtUtc: expiresAtUtc ?? this.expiresAtUtc,
      refreshToken: refreshToken != null ? refreshToken() : this.refreshToken,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accessToken': accessToken,
      'expiresAtUtc': expiresAtUtc.millisecondsSinceEpoch,
      'refreshToken': refreshToken,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() =>
      'AuthSession(expiresAtUtc: $expiresAtUtc, '
      'hasRefresh: ${refreshToken != null})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthSession &&
        other.accessToken == accessToken &&
        other.expiresAtUtc == expiresAtUtc &&
        other.refreshToken == refreshToken;
  }

  @override
  int get hashCode =>
      accessToken.hashCode ^ expiresAtUtc.hashCode ^ refreshToken.hashCode;
}
