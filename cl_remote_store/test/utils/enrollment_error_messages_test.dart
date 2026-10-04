import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

ServerException _e(String code) =>
    ServerException(statusCode: 409, code: code, message: 'raw $code');

void main() {
  test('Issue 128: a clashing approval names the clash', () {
    expect(
      enrollmentApproveErrorMessage(_e(SdkErrorCode.timeConflict)),
      'This member is already enrolled in an event at the same time.',
    );
  });

  test('Issue 130: a refused removal says the member already left', () {
    expect(
      enrollmentRemoveErrorMessage(_e(SdkErrorCode.invalidState)),
      'This member has already left the event.',
    );
  });

  test('Issue 128/130: other codes keep the shared enrollment mapping', () {
    final permission = _e(SdkErrorCode.insufficientPermission);
    expect(
      enrollmentApproveErrorMessage(permission),
      mapEnrollmentMutationError(permission),
    );
    expect(
      enrollmentRemoveErrorMessage(permission),
      mapEnrollmentMutationError(permission),
    );
  });
}
