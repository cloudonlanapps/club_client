import 'package:cl_club_evaluation/src/utils/evaluation_error_message.dart';
import 'package:club_sdk_2/club_sdk_2.dart' show SdkErrorCode, ServerException;
import 'package:flutter_test/flutter_test.dart';

ServerException _refusal(String code, {int status = 422}) => ServerException(
  statusCode: status,
  code: code,
  message: 'raw $code',
);

void main() {
  group('Issue 173: EvaluationErrorMessage names the Review Period '
      'refusals', () {
    test('Issue 173: NOT_ELIGIBLE', () {
      expect(
        EvaluationErrorMessage.of(_refusal(SdkErrorCode.notEligible)),
        'The member is not eligible for this event and period.',
      );
    });

    test('Issue 173: PERIOD_IN_FUTURE', () {
      expect(
        EvaluationErrorMessage.of(_refusal(SdkErrorCode.periodInFuture)),
        'The review period cannot end after today.',
      );
    });

    test('Issue 173: EVENT_NOT_FOUND', () {
      expect(
        EvaluationErrorMessage.of(
          _refusal(SdkErrorCode.eventNotFound, status: 404),
        ),
        'That event no longer exists.',
      );
    });

    test('Issue 173: DUPLICATE_EVALUATION and TEMPLATE_NAME_TAKEN come from '
        'the SDK codes', () {
      expect(
        EvaluationErrorMessage.of(_refusal(SdkErrorCode.duplicateEvaluation)),
        'A review of this member with this template and period already '
        'exists.',
      );
      final taken = _refusal(SdkErrorCode.templateNameTaken);
      expect(EvaluationErrorMessage.isTemplateNameTaken(taken), isTrue);
    });
  });
}
