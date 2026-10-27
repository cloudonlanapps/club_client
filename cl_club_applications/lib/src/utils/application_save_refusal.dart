import 'package:club_sdk_2/club_sdk_2.dart'
    show
        ApplicationDoesNotFitException,
        ApplicationIncompleteException,
        ApplicationLanguageNotOfferedException,
        ApplicationUnknownFactException,
        SdkErrorCode,
        ServerException;

import '../constants/application_fact_strings.dart';
import '../constants/application_view_strings.dart';
import 'application_places.dart';

/// What the state card shows inline when the server refuses to finalize a
/// template for something about the template itself (form rule 20): texts
/// missing a language, a `{gap}` naming no fact (club_client#389), a form
/// that does not fit page 1, or a print language the club does not offer
/// (club_client#396). Null for any other failure, which is a toast.
///
/// An incomplete template names every text the server lists, by its place
/// in the editor, with the print languages that text lacks, by name
/// (club_client#338): "Title: English; Declaration: Marathi". A club
/// label (`labels.<key>`) is named by its English text in [labels], the
/// club's labels: "Label: Full name — Hindi".
String? applicationSaveRefusal(
  Object error, {
  Map<String, Map<String, String>> labels = const {},
}) => switch (error) {
  ApplicationIncompleteException(:final missing) when missing.isNotEmpty =>
    ApplicationViewStrings.incomplete(
      missing
          .map((text) {
            final languages = text.languages.map(_languageName).join(', ');
            final key = text.labelKey;
            return key == null
                ? ApplicationViewStrings.incompleteText(
                    ApplicationPlaces.label(text.field),
                    languages,
                  )
                : ApplicationViewStrings.incompleteLabel(
                    applicationLabelName(key, labels),
                    languages,
                  );
          })
          .join(ApplicationViewStrings.incompleteSeparator),
    ),
  ApplicationLanguageNotOfferedException(:final languages)
      when languages.isNotEmpty =>
    ApplicationViewStrings.finalizeLanguageNotOffered([
      for (final code in languages) _languageName(code),
    ]),
  ApplicationUnknownFactException(:final gaps) when gaps.isNotEmpty =>
    ApplicationFactStrings.refused(
      gaps
          .map(
            (gap) => ApplicationFactStrings.unknownFact(
              ApplicationPlaces.label(gap.place),
              _languageName(gap.language),
              gap.gap,
            ),
          )
          .join(ApplicationFactStrings.separator),
    ),
  ApplicationDoesNotFitException(:final overflowPt) =>
    ApplicationViewStrings.doesNotFit(overflowPt),
  _ => null,
};

/// What a form shows inline when the server refuses a write for a
/// language the club does not offer (422 `APPLICATION_LANGUAGE_NOT_OFFERED`,
/// club_client#396): a template's print languages, a library text or a
/// label written in one. Null for any other failure.
String? applicationLanguageRefusal(Object error) => switch (error) {
  ApplicationLanguageNotOfferedException(:final languages)
      when languages.isNotEmpty =>
    ApplicationViewStrings.languageNotOffered([
      for (final code in languages) _languageName(code),
    ]),
  _ => null,
};

/// Label [key] as the editor names it: its English text among [labels],
/// or the key itself.
String applicationLabelName(
  String key,
  Map<String, Map<String, String>> labels,
) {
  final english = labels[key]?['en']?.trim() ?? '';
  return english.isEmpty ? key : english;
}

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
