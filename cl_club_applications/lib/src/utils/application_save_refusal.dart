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
/// missing a language, or a form that does not fit page 1. Null for any
/// other failure, which is a toast.
///
/// An incomplete template names every text the server lists, by its place
/// in the editor, with the print languages that text lacks, by name
/// (club_client#338): "Title: English; Declaration: Marathi".
String? applicationSaveRefusal(Object error) => switch (error) {
  ApplicationIncompleteException(:final missing) when missing.isNotEmpty =>
    ApplicationViewStrings.incomplete(
      missing
          .map(
            (text) => ApplicationViewStrings.incompleteText(
              ApplicationPlaces.label(text.field),
              text.languages.map(_languageName).join(', '),
            ),
          )
          .join(ApplicationViewStrings.incompleteSeparator),
    ),
  ApplicationDoesNotFitException(:final overflowPt) =>
    ApplicationViewStrings.doesNotFit(overflowPt),
  _ => null,
};

/// The name of print language [code] as the editor shows it; the code
/// itself when unknown.
String _languageName(String code) =>
    ApplicationViewStrings.languageNames[code] ?? code;

/// Whether [error] refuses a move because the template is no longer in
/// the state the screen showed (422 `INVALID_TRANSITION` or
/// `INVALID_STATE`): it changed elsewhere.
bool applicationChangedMeanwhile(Object error) =>
    error is ServerException &&
    (error.code == SdkErrorCode.invalidTransition ||
        error.code == SdkErrorCode.invalidState);
