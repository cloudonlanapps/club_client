import 'package:cl_club_forms/cl_club_forms.dart';

/// Made-up data the application form tests are mounted with: no club,
/// person or place here exists.
abstract final class ApplicationSamples {
  /// The languages of the label catalogue.
  static const List<ApplicationLanguageOption> languageOptions = [
    ApplicationLanguageOption(code: 'en', name: 'English'),
    ApplicationLanguageOption(code: 'mr', name: 'Marathi'),
    ApplicationLanguageOption(code: 'hi', name: 'Hindi'),
  ];

  /// English and Marathi, as an application prints in them.
  static const List<ApplicationLanguageOption> printLanguages = [
    ApplicationLanguageOption(code: 'en', name: 'English'),
    ApplicationLanguageOption(code: 'mr', name: 'Marathi'),
  ];

  /// The library texts.
  static const List<ApplicationClauseOption> clauses = [
    ApplicationClauseOption(
      id: 'header.camp',
      kind: ApplicationClauseKind.header,
      text: {'en': 'Camp: {dates}', 'mr': 'शिबिर: {dates}'},
    ),
    ApplicationClauseOption(
      id: 'declaration.camp',
      kind: ApplicationClauseKind.declaration,
      text: {'en': 'I declare the above is true.', 'mr': 'मी घोषित करतो.'},
    ),
    ApplicationClauseOption(
      id: 'rule.fee',
      kind: ApplicationClauseKind.rule,
      heading: {'en': 'Fee', 'mr': 'शुल्क'},
      text: {'en': 'A fee of {amount} is payable.', 'mr': '{amount} शुल्क.'},
    ),
    ApplicationClauseOption(
      id: 'rule.camp',
      kind: ApplicationClauseKind.rule,
      heading: {'en': 'Camp', 'mr': 'शिबिर'},
      text: {
        'en': 'A camp runs {dates} at {venue}.',
        'mr': '{dates} {venue} येथे शिबिर.',
      },
    ),
    ApplicationClauseOption(
      id: 'selection.attend_camp',
      kind: ApplicationClauseKind.selection,
      text: {'en': 'I will attend the camp {dates}.', 'mr': '{dates} शिबिर.'},
    ),
    ApplicationClauseOption(
      id: 'note.follow_rules',
      kind: ApplicationClauseKind.note,
      text: {'en': 'Follow the rules above.', 'mr': 'नियम पाळा.'},
    ),
  ];

  /// The library's choices.
  static const List<ApplicationChoiceOption> choices = [
    ApplicationChoiceOption(id: 'on_ice', text: {'en': 'on-ice'}),
    ApplicationChoiceOption(id: 'inline', text: {'en': 'inline'}),
  ];

  /// A few labels of the catalogue.
  static const List<ApplicationLabelOption> labels = [
    ApplicationLabelOption(
      id: 'field.full_name',
      text: {'en': 'Full name', 'mr': 'पूर्ण नाव', 'hi': 'पूरा नाम'},
    ),
    ApplicationLabelOption(
      id: 'field.past_experience',
      text: {'en': 'Past experience', 'mr': 'पूर्व अनुभव', 'hi': 'अनुभव'},
    ),
  ];
}
