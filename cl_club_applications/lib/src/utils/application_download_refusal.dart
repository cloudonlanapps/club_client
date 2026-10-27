import 'package:club_sdk_2/club_sdk_2.dart' show SdkErrorCode, ServerException;

import '../constants/application_view_strings.dart';

/// What a download button shows under itself when the server refuses a
/// form for a reason about the member or the application, or null when
/// [error] is about neither (the network, an unexpected error), which the
/// button toasts with a fixed message instead. The raw error never shows.
///
/// A member fitting several age categories
/// (`ApplicationCategoryRequiredException`) is not a refusal: the button
/// asks which one and downloads again (club_client#337).
String? applicationDownloadRefusal(Object error) {
  if (error is! ServerException) return null;
  return switch (error.code) {
    SdkErrorCode.applicationNotEligible => ApplicationViewStrings.notEligible,
    SdkErrorCode.identityDocumentRequired =>
      ApplicationViewStrings.identityRequired,
    SdkErrorCode.applicationNotPublished ||
    SdkErrorCode.applicationNotFound => ApplicationViewStrings.notPublished,
    SdkErrorCode.applicationCategoryNotFitting =>
      ApplicationViewStrings.categoryNotFitting,
    _ => null,
  };
}
