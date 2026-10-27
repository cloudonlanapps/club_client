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
    organisation: const ApplicationText({
      'en': 'Example Skating Club',
      'mr': 'उदाहरण क्लब',
    }),
    title: const ApplicationText({'en': 'Trial', 'mr': 'चाचणी'}),
    subtitle: const ApplicationText({
      'en': 'Northfield Rink',
      'mr': 'नॉर्थफील्ड',
    }),
    header: const [
      ApplicationHeaderItem.single(
        ApplicationText({'en': 'Camp: 1-15 Nov', 'mr': 'शिबिर'}),
      ),
      ApplicationHeaderItem.lines([
        ApplicationText({'en': 'Northfield Rink', 'mr': 'नॉर्थफील्ड'}),
        ApplicationText({'en': '98765 43210'}),
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
      ApplicationText({'en': 'I attend the camp', 'mr': 'शिबिर'}),
      ApplicationText({'en': 'I bring my own skates', 'mr': 'स्केट्स'}),
    ],
    declaration: const ApplicationText({
      'en': 'I will attend the camp',
      'mr': 'मी शिबिरास येईन',
    }),
    formFooter: const ApplicationText({'en': 'Play fair', 'mr': 'खेळ'}),
    terms: const [
      ApplicationTerm(
        heading: ApplicationText({'en': 'Fee', 'mr': 'शुल्क'}),
        body: ApplicationText({'en': 'The fee is 500', 'mr': '५००'}),
      ),
      ApplicationTerm(
        heading: ApplicationText({'en': 'Kit', 'mr': 'साहित्य'}),
        body: ApplicationText({'en': 'Wear a helmet', 'mr': 'हेल्मेट'}),
      ),
    ],
    termsNotes: const [
      ApplicationTermsNote(
        text: ApplicationText({'en': 'Follow the rules', 'mr': 'नियम'}),
      ),
      ApplicationTermsNote(
        text: ApplicationText({'en': 'Play hard', 'mr': 'खेळा'}),
        attribution: ApplicationText({'en': 'A coach'}),
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

  /// The clauses list (club_client#396): every text the club's, the
  /// built-in ones seeded with their key, the club's own with none.
  static final ApplicationClauseLibrary clauses = ApplicationClauseLibrary(
    languages: const ['en', 'mr', 'hi'],
    choices: const {
      'on_ice': {'en': 'on-ice', 'mr': 'बर्फावर'},
    },
    clauses: [
      libraryText(
        id: 1,
        key: 'header.camp',
        name: 'Header: camp',
        kind: ApplicationClauseKind.header,
        text: const ApplicationText({
          'en': 'Camp: {dates}',
          'mr': 'शिबिर: {dates}',
        }),
      ),
      libraryText(
        id: 2,
        key: 'declaration.camp',
        name: 'Declaration: camp',
        kind: ApplicationClauseKind.declaration,
        text: const ApplicationText({
          'en': 'I declare the above is true.',
          'mr': 'मी घोषित करतो.',
        }),
      ),
      libraryText(
        id: 3,
        key: 'rule.fee',
        name: 'Fee',
        kind: ApplicationClauseKind.rule,
        heading: const ApplicationText({'en': 'Fee', 'mr': 'शुल्क'}),
        text: const ApplicationText({
          'en': 'A fee of {amount} is payable.',
          'mr': '{amount} शुल्क.',
        }),
      ),
      libraryText(
        id: 4,
        key: 'selection.attend_camp',
        name: 'Selection: attend camp',
        text: const ApplicationText({
          'en': 'I will attend the camp {dates}.',
          'mr': '{dates}',
        }),
      ),
      libraryText(
        id: 5,
        key: 'note.follow_rules',
        name: 'Note: follow rules',
        kind: ApplicationClauseKind.note,
        text: const ApplicationText({
          'en': 'Follow the rules above.',
          'mr': 'नियम पाळा.',
        }),
      ),
      libraryText(
        text: const ApplicationText({
          'en': 'I will play the matches on {match_dates}.',
          'mr': 'मी {match_dates} रोजी सामने खेळेन.',
          'hi': 'मैं {match_dates} को खेलूँगा।',
        }),
      ),
    ],
  );

  /// One of the club's library texts.
  static ApplicationLibraryText libraryText({
    int id = 7,
    String? key,
    String name = 'Attend the matches',
    ApplicationClauseKind kind = ApplicationClauseKind.selection,
    ApplicationText? heading,
    ApplicationText text = const ApplicationText({
      'en': 'I will play the matches on {match_dates}.',
      'mr': 'मी {match_dates} रोजी सामने खेळेन.',
    }),
  }) => ApplicationLibraryText(
    id: id,
    key: key,
    kind: kind,
    name: name,
    heading: heading,
    text: text,
    createdAtUtc: DateTime.utc(2026, 10),
    updatedAtUtc: DateTime.utc(2026, 10),
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
