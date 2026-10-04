import 'dart:async';

import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:http/http.dart' as http;

/// The fixed text a failed sign-in shows. The raw error is logged, never
/// shown (club_core#157).
abstract final class LoginErrorMessages {
  /// Wrong username or password.
  static const invalidCredentials = 'Incorrect username or password';

  /// The account awaits approval.
  static const accountPending = 'Your account is awaiting approval';

  /// The account is blocked.
  static const accountBlocked = 'Your account is blocked';

  /// The account no longer exists.
  static const userNotFound = 'Account not found';

  /// The member has left the club.
  static const accountLeft =
      'This account has left the club. Contact the club to rejoin.';

  /// The session was revoked; signing in again starts a new one.
  static const sessionEnded = 'Your session has ended. Please sign in again.';

  /// No answer from the server.
  static const unreachable =
      'Could not reach the server. Check your connection and try again.';

  /// Anything else.
  static const fallback = 'Sign in failed. Please try again.';

  /// The message for a sign-in that failed with [error].
  static String forError(Object error) {
    if (error is http.ClientException || error is TimeoutException) {
      return unreachable;
    }
    final code = error is SdkException ? error.code : null;
    return switch (code) {
      SdkErrorCode.invalidCredentials => invalidCredentials,
      SdkErrorCode.accountPending => accountPending,
      SdkErrorCode.accountBlocked => accountBlocked,
      SdkErrorCode.userNotFound => userNotFound,
      SdkErrorCode.accountLeft => accountLeft,
      SdkErrorCode.invalidToken => sessionEnded,
      _ => fallback,
    };
  }
}
