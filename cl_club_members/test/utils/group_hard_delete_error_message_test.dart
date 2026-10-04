import 'package:cl_club_members/src/utils/group_hard_delete_error_message.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

ServerException _e(String code) =>
    ServerException(statusCode: 422, code: code, message: 'raw $code');

void main() {
  test('Issue 135: a live group asks to be soft-deleted first', () {
    expect(
      groupHardDeleteErrorMessage(_e(SdkErrorCode.hardDeleteNeedsSoftDelete)),
      'Soft-delete this group first, then permanently delete it.',
    );
  });

  test('Issue 135: any other refusal keeps the fixed message', () {
    expect(
      groupHardDeleteErrorMessage(_e(SdkErrorCode.insufficientPermission)),
      'Could not delete group.',
    );
    expect(
      groupHardDeleteErrorMessage(_e('NOT_DELETED')),
      'Could not delete group.',
    );
  });
}
