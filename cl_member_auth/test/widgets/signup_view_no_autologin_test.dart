@Tags(['source-shape'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Structural guard for #411.
///
/// The full submission path through `SignupForm` requires filling DOB,
/// gender, password, and a captcha-style availability check — too much
/// scaffolding for a focused regression. Instead, lock in the two
/// invariants the issue actually demanded by reading the source file:
///
///   1. `signup_view.dart` no longer calls `authStateProvider.notifier.login`
///      (auto-login removed).
///   2. The `_autoLoginError` state and its `ErrorView` fallback are gone.
///
/// If anyone re-introduces auto-login from SignupView, this test fires.
void main() {
  group('Issue 411: SignupView source shape', () {
    final source = File('lib/src/widgets/signup_view.dart').readAsStringSync();

    test('does not call authStateProvider.notifier.login', () {
      expect(
        source.contains('authStateProvider'),
        isFalse,
        reason:
            'SignupView must not touch auth state; signup is now a pure '
            'register call followed by an explicit acknowledgement screen.',
      );
    });

    test('does not retain the _autoLoginError fallback', () {
      expect(source.contains('_autoLoginError'), isFalse);
      expect(source.contains('automatic sign-in failed'), isFalse);
    });
  });
}
