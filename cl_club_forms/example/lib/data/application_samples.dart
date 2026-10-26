import 'package:cl_club_forms/cl_club_forms.dart';

/// A made-up application template and the library it is built from, for
/// the application forms: no club, person or place here exists.
abstract final class ApplicationSamples {
  /// The languages of the label catalogue.
  static const List<ApplicationLanguageOption> languageOptions = [
    ApplicationLanguageOption(code: 'en', name: 'English'),
    ApplicationLanguageOption(code: 'mr', name: 'Marathi'),
    ApplicationLanguageOption(code: 'hi', name: 'Hindi'),
  ];

  /// The template's print languages.
  static const List<ApplicationLanguageOption> printLanguages = [
    ApplicationLanguageOption(code: 'en', name: 'English'),
    ApplicationLanguageOption(code: 'mr', name: 'Marathi'),
  ];

  /// The clause library.
  static const List<ApplicationClauseOption> clauses = [
    ApplicationClauseOption(
      id: 'header.camp',
      kind: ApplicationClauseKind.header,
      text: {'en': 'Camp: {dates}', 'mr': 'शिबिर: {dates}'},
      gaps: {'dates': ApplicationFactType.dateRange},
    ),
    ApplicationClauseOption(
      id: 'declaration.camp',
      kind: ApplicationClauseKind.declaration,
      text: {
        'en': 'I declare the information above is true.',
        'mr': 'वरील माहिती खरी असल्याचे मी घोषित करतो.',
      },
    ),
    ApplicationClauseOption(
      id: 'rule.fee',
      kind: ApplicationClauseKind.rule,
      heading: {'en': 'Fee', 'mr': 'शुल्क'},
      text: {'en': 'A fee of {amount} is payable.', 'mr': '{amount} शुल्क.'},
      gaps: {'amount': ApplicationFactType.amount},
    ),
    ApplicationClauseOption(
      id: 'selection.attend_practice',
      kind: ApplicationClauseKind.selection,
      text: {
        'en': 'I will attend the practice sessions ({kinds}) from {dates}.',
        'mr': '{dates} सराव ({kinds}).',
      },
      gaps: {
        'dates': ApplicationFactType.dateRange,
        'kinds': ApplicationFactType.choices,
      },
    ),
    ApplicationClauseOption(
      id: 'note.follow_rules',
      kind: ApplicationClauseKind.note,
      text: {'en': 'Follow the rules above.', 'mr': 'वरील नियम पाळा.'},
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

  /// The template, as its JSON holds it.
  static const Map<String, dynamic> template = {
    'languages': ['en', 'mr'],
    'facts': {
      'venue': {
        'type': 'name',
        'value': {'en': 'City Rink', 'mr': 'शहर रिंक'},
      },
      'phone': {'type': 'name', 'value': '555 0100'},
      'camp': {'type': 'date_range', 'from': '2026-11-16', 'to': '2026-11-17'},
      'report': {'type': 'time', 'value': '06:00'},
      'fee': {'type': 'amount', 'value': 1500},
      'kinds': {
        'type': 'choices',
        'value': ['on_ice', 'inline'],
      },
    },
    'organisation': {'en': 'Example Club', 'mr': 'उदाहरण क्लब'},
    'title': {'en': 'Training Camp Registration', 'mr': 'शिबिर नोंदणी'},
    'subtitle': {'fact': 'camp'},
    'header': [
      {'fact': 'venue'},
      [
        {
          'clause': 'header.camp',
          'args': {'dates': 'camp'},
        },
        {'fact': 'phone'},
      ],
    ],
    'age_categories': [
      {
        'label': {'en': 'Under 12', 'mr': 'बारा वर्षांखालील'},
        'born_on_or_after': '2014-01-01',
      },
      {
        'label': {'en': 'Senior'},
        'born_on_or_before': '2007-12-31',
        'genders': ['female', 'male'],
      },
    ],
    'selections': [
      {
        'clause': 'selection.attend_practice',
        'args': {'dates': 'camp', 'kinds': 'kinds'},
      },
    ],
    'declaration': {'clause': 'declaration.camp'},
    'form_footer': {'en': 'See you on the ice', 'mr': 'बर्फावर भेटूया'},
    'terms': [
      {
        'clause': 'rule.fee',
        'args': {'amount': 'fee'},
      },
      {
        'heading': {'en': 'Kit', 'mr': 'साहित्य'},
        'body': {'en': 'Bring a helmet and gloves.'},
      },
    ],
    'terms_notes': [
      {
        'text': {'clause': 'note.follow_rules'},
        'attribution': {'en': '— Example Club'},
      },
    ],
    'label_overrides': {
      'field.past_experience': {
        'en': 'Past experience in any sport',
        'mr': 'पूर्व अनुभव',
        'hi': 'अनुभव',
      },
    },
  };

  /// The template's facts, by name and type.
  static Map<String, ApplicationFactType> get facts =>
      ApplicationFactType.ofFacts(template[ApplicationFormFields.factsId]);
}
