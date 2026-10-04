import 'package:club_sdk_2/club_sdk_2.dart' show SdkErrorCode, ServerException;

/// The message for a refused profile section save: a fixed, friendly line
/// per known code, never the raw error. An email another user already has
/// is named (club_core#131).
String profileSaveErrorMessage(ServerException e) => switch (e.code) {
  SdkErrorCode.insufficientPermission =>
    'You do not have permission for that action.',
  SdkErrorCode.duplicateEmail => 'That email is already in use.',
  _ => 'Could not save. Please try again.',
};
