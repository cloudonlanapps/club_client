import 'package:club_sdk_2/club_sdk_2.dart'
    show
        ApplicationDoesNotFitException,
        ApplicationIncompleteException,
        SdkErrorCode,
        ServerException;

import '../constants/application_view_strings.dart';
import 'application_places.dart';

/// What the state card shows inline when the server refuses to save a
/// template for something about the template itself (form rule 20): texts
/// missing a language, a form that does not fit page 1, a broken clause or
/// fact reference. Null for any other failure, which is a toast.
String? applicationSaveRefusal(Object error) => switch (error) {
  ApplicationIncompleteException(:final missing, :final language) =>
    ApplicationViewStrings.incomplete(
      ApplicationViewStrings.languageNames[language] ?? language ?? '',
      ApplicationPlaces.join(missing),
    ),
  ApplicationDoesNotFitException(:final overflowPt) =>
    ApplicationViewStrings.doesNotFit(overflowPt),
  ServerException(code: SdkErrorCode.applicationInvalidReference) =>
    ApplicationViewStrings.invalidReference,
  _ => null,
};

/// Whether [error] refuses a move because the template is no longer in
/// the state the screen showed (422 `INVALID_TRANSITION` or
/// `INVALID_STATE`): it changed elsewhere.
bool applicationChangedMeanwhile(Object error) =>
    error is ServerException &&
    (error.code == SdkErrorCode.invalidTransition ||
        error.code == SdkErrorCode.invalidState);
