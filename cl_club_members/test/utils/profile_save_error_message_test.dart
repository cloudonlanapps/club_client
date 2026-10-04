import 'package:cl_club_members/src/utils/profile_save_error_message.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

ServerException _e(String code) =>
    ServerException(statusCode: 409, code: code, message: 'raw $code');

void main() {
  test('Issue 131: an email already in use is named', () {
    expect(
      profileSaveErrorMessage(_e(SdkErrorCode.duplicateEmail)),
      'That email is already in use.',
    );
  });

  test('Issue 131: permission and anything else keep their messages', () {
    expect(
      profileSaveErrorMessage(_e(SdkErrorCode.insufficientPermission)),
      'You do not have permission for that action.',
    );
    expect(
      profileSaveErrorMessage(_e('SOMETHING_ELSE')),
      'Could not save. Please try again.',
    );
  });
}
