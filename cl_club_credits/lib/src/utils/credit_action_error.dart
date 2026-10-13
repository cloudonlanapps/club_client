import 'package:cl_club_forms/cl_club_forms.dart' show CreditFormFields;
import 'package:cl_remote_store/cl_remote_store.dart' show schemaFieldErrors;
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

/// The server's name for a number of credits.
const String creditServerCredits = 'credits';

/// The server's name for a transfer's penalty.
const String creditServerPenalty = 'penalty';

/// The server's name for the first day a package is valid.
const String creditServerValidFrom = 'validFromUtc';

/// The server's name for the last day a package is valid.
const String creditServerValidUntil = 'validUntilUtc';

/// The server's name for the programme a package is for.
const String creditServerEventId = 'eventId';

/// The server's name for the trial flag.
const String creditServerIsTrial = 'isTrial';

/// The server's name for the reason.
const String creditServerReason = 'reason';

/// The fields of the credit actions, as the server names them in a schema
/// rejection (club_client#114), each with the id of the form field that
/// holds it.
const Map<String, String> creditSchemaFieldIds = {
  creditServerCredits: CreditFormFields.creditsId,
  creditServerPenalty: CreditFormFields.penaltyId,
  creditServerValidFrom: CreditFormFields.validFromId,
  creditServerValidUntil: CreditFormFields.validUntilId,
  creditServerEventId: CreditFormFields.programmeId,
  creditServerIsTrial: CreditFormFields.trialId,
  creditServerReason: CreditFormFields.reasonId,
};

/// What [kind]'s form shows for the refusal [e]: its fixed message on the
/// field the refusal is about ([creditActionRefusedFieldId]), or the
/// server's reason on each field its schema rejects. Empty when [e] is
/// about none of the form's fields, which leaves it to a toast.
Map<String, String> creditActionFieldErrors(
  ServerException e,
  CreditActionKind kind,
) {
  final fieldId = creditActionRefusedFieldId(e, kind);
  if (fieldId != null) return {fieldId: creditActionErrorMessage(e)};
  return schemaFieldErrors(e, creditSchemaFieldIds);
}
