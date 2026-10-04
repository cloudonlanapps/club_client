import 'dart:async';

import 'package:cl_member_auth/src/utils/login_error_messages.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

ServerException _refused(String code) => ServerException(
  statusCode: 401,
  code: code,
  message: 'raw server text for $code',
);

void main() {
  group('Issue 157: login errors map to fixed messages', () {
    test('Issue 157: ACCOUNT_LEFT says the account has left the club', () {
      final message = LoginErrorMessages.forError(
        _refused(SdkErrorCode.accountLeft),
      );
      expect(message, LoginErrorMessages.accountLeft);
      expect(message, contains('left the club'));
      expect(message, contains('rejoin'));
    });

    test(
      'Issue 157: INVALID_CREDENTIALS and ACCOUNT_BLOCKED are unchanged',
      () {
        expect(
          LoginErrorMessages.forError(
            _refused(SdkErrorCode.invalidCredentials),
          ),
          'Incorrect username or password',
        );
        expect(
          LoginErrorMessages.forError(_refused(SdkErrorCode.accountBlocked)),
          'Your account is blocked',
        );
      },
    );

    test('Issue 157: a revoked session asks to sign in again', () {
      expect(
        LoginErrorMessages.forError(_refused(SdkErrorCode.invalidToken)),
        LoginErrorMessages.sessionEnded,
      );
    });

    test('Issue 157: an unreachable server names the connection', () {
      expect(
        LoginErrorMessages.forError(http.ClientException('Broken pipe')),
        LoginErrorMessages.unreachable,
      );
      expect(
        LoginErrorMessages.forError(TimeoutException('slow')),
        LoginErrorMessages.unreachable,
      );
    });

    test('Issue 157: an unmapped error never shows its raw text', () {
      final errors = <Object>[
        _refused('SOMETHING_NEW'),
        const ServerException(
          statusCode: 500,
          code: 'INTERNAL_ERROR',
          message: 'raw server text',
        ),
        StateError('raw bug text'),
      ];
      for (final error in errors) {
        final message = LoginErrorMessages.forError(error);
        expect(message, LoginErrorMessages.fallback);
        expect(message, isNot(contains('raw')));
      }
    });
  });
}
