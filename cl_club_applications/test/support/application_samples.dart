import 'package:club_sdk_2/club_sdk_2.dart';

/// Made-up application data the tests are mounted with: no club, person or
/// place here exists.
abstract final class ApplicationSamples {
  /// A template's content with every kind of value.
  static final ApplicationContent content = ApplicationContent(
    languages: const ['en', 'mr'],
    facts: {
      'venue': const ApplicationFact.localizedName({
        'en': 'Northfield Rink',
        'mr': 'नॉर्थफील्ड',
      }),
      'phone': const ApplicationFact.name('98765 43210'),
      'trial': ApplicationFact.date(DateTime.utc(2026, 11, 19)),
      'camp': ApplicationFact.dateRange(
        DateTime.utc(2026, 11),
        DateTime.utc(2026, 11, 15),
      ),
      'start': const ApplicationFact.time('06:00'),
      'fee': const ApplicationFact.amount(500),
      'kinds': const ApplicationFact.choices(['on_ice']),
    },
    organisation: const ApplicationText.custom({
      'en': 'Example Skating Club',
      'mr': 'उदाहरण क्लब',
    }),
    title: const ApplicationText.custom({'en': 'Trial', 'mr': 'चाचणी'}),
    subtitle: const ApplicationText.fact('venue'),
    header: const [
      ApplicationHeaderItem.single(
        ApplicationText.clause('header.camp', args: {'dates': 'camp'}),
      ),
      ApplicationHeaderItem.lines([
        ApplicationText.fact('venue'),
        ApplicationText.fact('phone'),
      ]),
    ],
    ageCategories: [
      ApplicationAgeCategory(
        label: const {'en': 'Under-12', 'mr': '१२ खालील'},
        bornOnOrAfterUtc: DateTime.utc(2014),
        genders: const [Gender.male],
      ),
      ApplicationAgeCategory(
        label: const {'en': 'Open'},
        bornOnOrBeforeUtc: DateTime.utc(2013, 12, 31),
      ),
    ],
    selections: const [
      ApplicationText.clause('selection.attend_camp', args: {'dates': 'camp'}),
      ApplicationText.custom({'en': 'I bring my own skates', 'mr': 'स्केट्स'}),
    ],
    declaration: const ApplicationText.clause('declaration.camp'),
    formFooter: const ApplicationText.custom({'en': 'Play fair', 'mr': 'खेळ'}),
    terms: const [
      ApplicationTerm.clause('rule.fee', args: {'amount': 'fee'}),
      ApplicationTerm.custom(
        heading: ApplicationText.custom({'en': 'Kit', 'mr': 'साहित्य'}),
        body: ApplicationText.custom({'en': 'Wear a helmet', 'mr': 'हेल्मेट'}),
      ),
    ],
    termsNotes: const [
      ApplicationTermsNote.clause('note.follow_rules'),
      ApplicationTermsNote.custom(
        text: ApplicationText.custom({'en': 'Play hard', 'mr': 'खेळा'}),
        attribution: ApplicationText.custom({'en': 'A coach'}),
      ),
    ],
    labelOverrides: const {
      'field.full_name': {'en': 'Player name', 'mr': 'खेळाडूचे नाव'},
    },
  );

  /// The label catalogue.
  static const ApplicationLabels labels = ApplicationLabels(
    languages: ['en', 'mr', 'hi'],
    labels: {
      'field.full_name': {'en': 'Full name', 'mr': 'पूर्ण नाव', 'hi': 'नाम'},
    },
  );

  /// The clause library.
  static const ApplicationClauseLibrary clauses = ApplicationClauseLibrary(
    languages: ['en', 'mr', 'hi'],
    choices: {
      'on_ice': {'en': 'on-ice', 'mr': 'बर्फावर'},
    },
    clauses: {
      'header.camp': ApplicationClause(
        kind: 'header',
        gaps: {'dates': ApplicationFactType.dateRange},
        text: {'en': 'Camp: {dates}', 'mr': 'शिबिर: {dates}'},
      ),
      'declaration.camp': ApplicationClause(
        kind: 'declaration',
        text: {'en': 'I declare the above is true.', 'mr': 'मी घोषित करतो.'},
      ),
      'rule.fee': ApplicationClause(
        kind: 'rule',
        gaps: {'amount': ApplicationFactType.amount},
        heading: {'en': 'Fee', 'mr': 'शुल्क'},
        text: {'en': 'A fee of {amount} is payable.', 'mr': '{amount} शुल्क.'},
      ),
      'selection.attend_camp': ApplicationClause(
        kind: 'selection',
        gaps: {'dates': ApplicationFactType.dateRange},
        text: {'en': 'I will attend the camp {dates}.', 'mr': '{dates}'},
      ),
      'note.follow_rules': ApplicationClause(
        kind: 'note',
        text: {'en': 'Follow the rules above.', 'mr': 'नियम पाळा.'},
      ),
    },
  );

  /// A template of [content] in [status].
  static ApplicationTemplate template({
    int id = 5,
    ApplicationStatus status = ApplicationStatus.draft,
    ApplicationContent? content,
    ApplicationLayout? layout,
  }) => ApplicationTemplate(
    id: id,
    status: status,
    content: content ?? ApplicationSamples.content,
    layout: layout,
    createdAtUtc: DateTime.utc(2026, 10),
    updatedAtUtc: DateTime.utc(2026, 10),
  );
}
