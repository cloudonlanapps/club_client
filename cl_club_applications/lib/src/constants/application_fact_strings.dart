/// What the application editor says about facts and the `{name}` gaps that
/// print them (club_client#389): the Facts help, and the State card's
/// lines for a gap naming no fact.
abstract final class ApplicationFactStrings {
  /// What the help button is, for a screen reader.
  static const String helpLabel = 'About facts';

  /// The help's heading.
  static const String helpTitle = 'What is a fact?';

  /// What a fact is, and how a text uses it.
  static const String helpIntro =
      'A fact is a value typed once for this application: a date, a venue, '
      'a fee. Write {name} in any text, in any section, and the form prints '
      "that fact's value there, in each print language.";

  /// Above the examples.
  static const String helpExamplesTitle = 'One example of each type:';

  /// One example per type of fact: the type, the fact and its value, and
  /// a text using it with what it prints. The printed forms follow the
  /// server's formats.
  static const List<(String, String, String)> helpExamples = [
    (
      'Name',
      'venue = Northfield Rink',
      '"at {venue}" prints "at Northfield '
          'Rink"',
    ),
    (
      'Date',
      'trial = 19 Nov 2026',
      '"on {trial}" prints "on 19 November '
          '2026" / "19 नोव्हेंबर 2026"',
    ),
    (
      'Date range',
      'match_dates = 1–15 Nov 2026',
      '"from {match_dates}" '
          'prints "from 1–15 November 2026"',
    ),
    (
      'Time',
      'report_time = 06:00',
      '"at {report_time}" prints "at 6:00 am" '
          '/ "सकाळी 6:00"',
    ),
    ('Amount', 'fee = 1500', '"₹{fee}" prints "₹1,500"'),
    (
      'Choices',
      'kinds = on-ice, inline',
      '"{kinds}" prints "on-ice and '
          'inline"',
    ),
  ];

  /// Under the examples.
  static const String helpNote =
      'A name is lowercase letters, digits and _, starting with a letter. A '
      '{name} that names no fact is listed on the State card, and the '
      'application cannot be saved until a fact has that name.';

  /// One example of the help, as shown: its [type], [fact] and [use].
  static String helpExample(String type, String fact, String use) =>
      '$type — $fact: $use';

  /// A line of the State card: a gap at [place], in [language], naming no
  /// fact; "Selection 2 (Marathi): no fact named match_date".
  static String unknownFact(String place, String language, String gap) =>
      '$place ($language): no fact named $gap';

  /// The heading of the list of gaps naming no fact: add the fact under
  /// Facts, or change the text.
  static const String unknownIntro = 'Unknown facts:';

  /// Finalize refused by the server for gaps naming no fact ([gaps], each a
  /// [unknownFact] line, joined by `; `).
  static String refused(String gaps) =>
      'Finalize was refused: these gaps name no fact. $gaps.';

  /// Separates the gaps of a refusal.
  static const String separator = '; ';
}
