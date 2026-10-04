import 'package:club_sdk_2/club_sdk_2.dart' show SdkErrorCode, ServerException;

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
