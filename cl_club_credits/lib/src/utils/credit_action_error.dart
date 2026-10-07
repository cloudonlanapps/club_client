import 'package:cl_club_forms/cl_club_forms.dart' show CreditFormFields;
import 'package:club_sdk_2/club_sdk_2.dart' show SdkErrorCode, ServerException;

import '../models/credit_action_kind.dart';

/// Shown when a credit action fails with no more specific message.
const String creditActionSaveFailedMessage =
    'Could not save. Please try again.';

/// The fixed message a refused credit action shows (club_core#101); the
/// raw exception is never shown.
String creditActionErrorMessage(ServerException e) => switch (e.code) {
  SdkErrorCode.insufficientBalance => 'More than remains unspent.',
  SdkErrorCode.accountClosed => 'This package is closed.',
  SdkErrorCode.invalidValidityWindow => 'Check the validity dates.',
  SdkErrorCode.invalidCreditAmount => 'Check the number of credits.',
  SdkErrorCode.creditNotApplicable => 'Credit applies to programmes only.',
  _ => creditActionSaveFailedMessage,
};

/// The id of the field of [kind]'s form that the refusal [e] is about, or
/// null when it is about none of that form's fields.
String? creditActionRefusedFieldId(ServerException e, CreditActionKind kind) {
  final amountId = switch (kind) {
    CreditActionKind.grant ||
    CreditActionKind.reverse => CreditFormFields.creditsId,
    CreditActionKind.transfer => CreditFormFields.penaltyId,
    CreditActionKind.extend => null,
  };
  return switch (e.code) {
    SdkErrorCode.insufficientBalance =>
      kind == CreditActionKind.grant ? null : amountId,
    SdkErrorCode.invalidCreditAmount => amountId,
    SdkErrorCode.invalidValidityWindow =>
      kind == CreditActionKind.reverse ? null : CreditFormFields.validUntilId,
    SdkErrorCode.creditNotApplicable =>
      kind == CreditActionKind.grant ? CreditFormFields.programmeId : null,
    _ => null,
  };
}
