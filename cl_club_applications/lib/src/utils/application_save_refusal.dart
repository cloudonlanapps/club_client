import 'package:club_sdk_2/club_sdk_2.dart'
    show
        ApplicationDoesNotFitException,
        ApplicationIncompleteException,
        ApplicationMissingText,
        SdkErrorCode,
        ServerException;

import '../constants/application_view_strings.dart';
import 'application_places.dart';

/// What the state card shows inline when the server refuses to save a
/// template for something about the template itself (form rule 20): texts
/// missing a language, or a form that does not fit page 1. Null for any
/// other failure, which is a toast.
String? applicationSaveRefusal(Object error) => switch (error) {
  ApplicationIncompleteException(
    missing: [final ApplicationMissingText first, ...final rest],
  ) =>
    ApplicationViewStrings.incomplete(
      ApplicationPlaces.label(first.field),
      first.languages
          .map((code) => ApplicationViewStrings.languageNames[code] ?? code)
          .join(', '),
      rest.length,
    ),
  ApplicationDoesNotFitException(:final overflowPt) =>
    ApplicationViewStrings.doesNotFit(overflowPt),
  _ => null,
};

/// Whether [error] refuses a move because the template is no longer in
/// the state the screen showed (422 `INVALID_TRANSITION` or
/// `INVALID_STATE`): it changed elsewhere.
bool applicationChangedMeanwhile(Object error) =>
    error is ServerException &&
    (error.code == SdkErrorCode.invalidTransition ||
        error.code == SdkErrorCode.invalidState);
