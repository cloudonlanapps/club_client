import 'package:cl_member_onboarding/src/models/identity_document_upload_errors.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

ServerException _err(String code, {int status = 422}) => ServerException(
  statusCode: status,
  code: code,
  message: 'server says $code',
);

void main() {
  group('Issue 754: IdentityDocumentUploadErrors.friendlyMessage', () {
    test('maps ENCRYPTION_NOT_CONFIGURED (503) to a "temporarily unavailable" '
        'message', () {
      final msg = IdentityDocumentUploadErrors.friendlyMessage(
        _err('ENCRYPTION_NOT_CONFIGURED', status: 503),
      );
      expect(msg, isNotNull);
      expect(msg, contains('temporarily unavailable'));
    });

    test('maps both over-cap codes to a "too large" message', () {
      for (final code in ['ENCRYPTED_FILE_TOO_LARGE', 'FILE_TOO_LARGE']) {
        final msg = IdentityDocumentUploadErrors.friendlyMessage(_err(code));
        expect(msg, isNotNull, reason: code);
        expect(msg, contains('too large'), reason: code);
      }
    });

    test('returns null for unrelated server errors (caller falls back to the '
        'generic message)', () {
      expect(
        IdentityDocumentUploadErrors.friendlyMessage(
          _err('INVALID_MEDIA_TYPE'),
        ),
        isNull,
      );
      expect(
        IdentityDocumentUploadErrors.friendlyMessage(_err('CONVERSION_FAILED')),
        isNull,
      );
    });
  });
}
