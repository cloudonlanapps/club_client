/// Every text the Applications views show (club_client#321).
abstract final class ApplicationViewStrings {
  /// The page's heading, and the profile section's.
  static const String applications = 'Applications';

  /// What a member does with a downloaded form.
  static const String printNote =
      'Download your form, print it, affix a passport-size photograph, sign '
      'it and hand it in.';

  /// A member's list with nothing published.
  static const String noneOpen = 'No applications are open right now.';

  /// A member's list without an identity document.
  static const String needsIdentityDocument =
      'Applications are offered once you have uploaded an identity '
      'document. You have none on file yet.';

  /// The admin's list with no template.
  static const String noTemplates =
      'No applications yet. Create one, or duplicate last season’s.';

  /// The profile section of a member with nothing to download.
  static const String nothingToDownload =
      'No application is published right now.';

  /// The list could not be read.
  static const String loadFailed = 'Could not load the applications.';

  /// A template that is gone or not yours to see.
  static const String notFound = 'This application is not available.';

  /// The preview button.
  static const String preview = 'Preview';

  /// The create button and dialog title.
  static const String create = 'Create application';

  /// The duplicate action.
  static const String duplicate = 'Duplicate';

  /// A dialog's cancel button.
  static const String cancel = 'Cancel';

  /// A dialog's save button.
  static const String save = 'Save';

  /// A template without an English title.
  static const String untitled = 'Untitled application';

  /// Joins the parts of a caption.
  static const String separator = ' · ';

  /// The state actions' card.
  static const String stateTitle = 'State';

  /// The stored layout, once saved.
  static String layout(String name) => 'Layout: $name';

  /// A draft has no layout until it is saved.
  static const String noLayout =
      'Layout: decided when the application is saved';

  /// Read-only outside a draft.
  static const String revertToEdit =
      'Saved and published applications are read-only: revert to a draft to '
      'edit.';

  /// The heading of the client's own check.
  static const String missingTitle = 'Still missing before it can be saved';

  /// What the client's check lists.
  static const String missingIntro =
      'These texts are missing, or are not written in every print language:';

  /// A template created.
  static const String created = 'Application created.';

  /// A template duplicated.
  static const String duplicated = 'Copy created as a draft.';

  /// A write failed for no reason about what was typed.
  static const String writeFailed =
      'Could not reach the server. Please try again.';

  /// A section saved.
  static String sectionSaved(String section) => '$section updated.';

  /// A section's write refused because the template is no longer a draft.
  static const String notDraftAnymore =
      'Only a draft can be changed, and this application is no longer one. '
      'It has been reloaded.';

  /// A move refused because the template changed meanwhile.
  static const String changedMeanwhile =
      'This application was changed elsewhere and has been reloaded.';

  /// Save refused: texts missing a language.
  static String incomplete(String language, String places) =>
      'Save was refused: these texts are missing or lack $language: '
      '$places.';

  /// Save refused: the details do not fit page 1.
  static String doesNotFit(double? overflowPt) =>
      'Save was refused: the member’s details do not fit on page 1'
      '${overflowPt == null ? '' : ' (over by ${overflowPt.round()} pt)'}. '
      'Remove some age categories.';

  /// Save refused: a clause or fact reference is broken.
  static const String invalidReference =
      'Save was refused: a text names a clause or fact the application does '
      'not have, or a fact of the wrong type. Check the facts each clause '
      'uses.';

  /// Delete's confirmation title.
  static const String deleteTitle = 'Delete this application?';

  /// Delete's confirmation message.
  static const String deleteMessage =
      'It is removed from the list. Members never saw a draft or a saved '
      'application.';

  /// A download refused: no age category matches.
  static const String notEligible =
      'Not eligible for this application: none of its age categories matches '
      'the date of birth and gender on the profile.';

  /// A download refused: no identity document.
  static const String identityRequired =
      'Upload an identity document first: applications are offered only '
      'then.';

  /// A download refused: no longer published.
  static const String notPublished = 'This application is no longer published.';

  /// The question before a member downloads their own form
  /// (club_client#340).
  static const String profileCompleteTitle = 'Is your profile complete?';

  /// Why the question is asked.
  static const String profileCompleteMessage =
      'Your form is printed from your profile. Check that your details are '
      'complete and up to date before you download it.';

  /// The answer that downloads the form.
  static const String profileCompleteYes = 'Yes';

  /// The answer that does not download it.
  static const String profileCompleteNo = 'No';

  /// A download failed for another reason.
  static const String downloadFailed =
      'Could not download the form. Please try again.';

  /// The status as shown.
  static const Map<String, String> statusLabels = {
    'draft': 'Draft',
    'saved': 'Saved',
    'published': 'Published',
  };

  /// A print language's name by its code; the code itself when unknown.
  static const Map<String, String> languageNames = {
    'en': 'English',
    'mr': 'Marathi',
    'hi': 'Hindi',
  };

  /// Months as a day is shown (`19 Nov 2026`).
  static const List<String> months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// The read mode's row of the print languages.
  static const String printLanguages = 'Print languages';

  /// The read mode's row of the organisation.
  static const String organisation = 'Organisation';

  /// The read mode's row of the title.
  static const String title = 'Title';

  /// The read mode's row of the subtitle.
  static const String subtitle = 'Subtitle';

  /// The read mode's row of the footer line.
  static const String formFooter = 'Footer line';

  /// The read mode's row of the declaration.
  static const String declaration = 'Declaration';

  /// The read mode's row of header item [n] (from 1).
  static String headerItem(int n) => 'Item $n';

  /// The read mode's row of selection [n] (from 1).
  static String selection(int n) => 'Selection $n';

  /// The read mode's row of term [n] (from 1) without a heading.
  static String term(int n) => 'Term $n';

  /// The read mode's row of note [n] (from 1).
  static String note(int n) => 'Note $n';

  /// An age category open to every birth date.
  static const String anyBirthDate = 'Any date of birth';

  /// An age category's birth dates.
  static String bornBetween(String? from, String? to) => switch ((from, to)) {
    (final String f, final String t) => 'Born $f to $t',
    (final String f, null) => 'Born on or after $f',
    (null, final String t) => 'Born on or before $t',
    _ => anyBirthDate,
  };

  /// The genders an age category takes, as shown.
  static const Map<String, String> genderNames = {
    'male': 'Male',
    'female': 'Female',
    'other': 'Other',
  };

  /// What an empty section says in the editor.
  static const String emptySection = 'Nothing here yet. Tap to add.';

  /// A missing place's name in the client's check and a refusal: the
  /// template's own keys as the forms and the server spell them.
  static const Map<String, String> placeNames = {
    'title': 'Title',
    'declaration': 'Declaration',
    'form_footer': 'Footer line',
    'formFooter': 'Footer line',
    'organisation': 'Organisation',
  };

  /// Save's reason while texts are missing.
  static String textsMissing(int n) =>
      n == 1 ? '1 text missing' : '$n texts missing';

  /// Marks an item of a list.
  static const String bullet = '• ';
}
