import 'package:cl_club_credits/src/models/credit_action_kind.dart';
import 'package:cl_club_credits/src/utils/credit_action_error.dart';
import 'package:cl_club_forms/cl_club_forms.dart' show CreditFormFields;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

/// A schema rejection (422) naming the body fields [names], each with the
/// reason "refused".
ServerException _rejection(List<String> names) => ServerException(
  statusCode: 422,
  code: SdkErrorCode.validationError,
  message: 'refused',
  details: {
    ServerException.refusedFieldsKey: [
      for (final name in names)
        {
          'loc': ['body', name],
          'msg': 'refused',
        },
    ],
  },
);

void main() {
  group('Issue 114: a schema rejection shows on the credit field it names', () {
    test('Issue 114: Add credit puts it on the credits, the dates, the '
        'programme, the trial flag and the reason', () {
      expect(
        creditActionFieldErrors(
          _rejection([
            'credits',
            'validFromUtc',
            'validUntilUtc',
            'eventId',
            'isTrial',
            'reason',
          ]),
          CreditActionKind.grant,
        ).keys,
        {
          CreditFormFields.creditsId,
          CreditFormFields.validFromId,
          CreditFormFields.validUntilId,
          CreditFormFields.programmeId,
          CreditFormFields.trialId,
          CreditFormFields.reasonId,
        },
      );
    });

    test('Issue 114: Transfer puts it on the penalty', () {
      expect(
        creditActionFieldErrors(
          _rejection(['penalty']),
          CreditActionKind.transfer,
        ),
        {CreditFormFields.penaltyId: 'Refused'},
      );
    });

    test('Issue 114: a refusal the form has its own words for keeps them, '
        'and one about nothing it holds names no field', () {
      const insufficient = ServerException(
        statusCode: 422,
        code: SdkErrorCode.insufficientBalance,
        message: 'raw',
      );

      expect(
        creditActionFieldErrors(insufficient, CreditActionKind.reverse),
        {CreditFormFields.creditsId: creditActionErrorMessage(insufficient)},
      );
      expect(
        creditActionFieldErrors(
          _rejection(['membername']),
          CreditActionKind.grant,
        ),
        isEmpty,
      );
    });
  });
}
