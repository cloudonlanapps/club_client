import '../../models/application/application_clause_kind.dart';
import '../../models/application/application_fact_type.dart';

/// Labels, hints and messages of the application forms.
abstract final class ApplicationFormStrings {
  /// Label of the print languages.
  static const String printLanguages = 'Print languages';

  /// The print languages when English is alone.
  static const String englishOnly = 'English only';

  /// The print languages English and [other].
  static String englishAnd(String other) => 'English and $other';

  /// Label of the title of a new application.
  static const String titleInEnglish = 'Title (English)';

  /// Label of the organisation.
  static const String organisation = 'Organisation';

  /// Label of the title.
  static const String title = 'Title';

  /// Label of the subtitle.
  static const String subtitle = 'Subtitle';

  /// Label of the footer line.
  static const String formFooter = 'Footer line';

  /// Label of the declaration.
  static const String declaration = 'Declaration';

  /// Label of the library texts a section offers (club_client#336, #389).
  static const String library = 'From the library';

  /// What tapping a library text does.
  static const String libraryHint =
      'Tap a text to add it as written, in each print language. A {name} '
      'in it prints the fact of that name; edit it like any other text.';

  /// The mark of a club library text named [name] in a section's list.
  static String clubText(String name) => "Club's text: $name";

  /// Label of a library text's kind (club_client#389).
  static const String libraryKind = 'Used for';

  /// Placeholder of a library text's kind.
  static const String libraryKindPlaceholder = 'Pick where it is used';

  /// Label of a library text's name.
  static const String libraryName = 'Name';

  /// Label of a library text's heading, a term's alone.
  static const String libraryHeading = 'Heading';

  /// Label of a library text's text.
  static const String libraryText = 'Text';

  /// What a library text may hold.
  static const String libraryTextHint =
      'Write it in each language you need. A {name} prints the fact of that '
      'name of the template it is pasted into.';

  /// Refusal of a library text with no kind.
  static const String libraryKindRequired = 'Pick where the text is used';

  /// Refusal of a library text with no name.
  static const String libraryNameRequired = 'Give the text a name';

  /// Refusal of a library text's name longer than [max] characters.
  static String libraryNameTooLong(int max) =>
      'Keep the name to $max characters';

  /// Refusal of a library text with no text.
  static const String libraryTextRequired =
      'Write the text in one language '
      'at least';

  /// The name of a library text's [kind], as shown.
  static String kindName(ApplicationClauseKind kind) => switch (kind) {
    ApplicationClauseKind.header => 'Header item',
    ApplicationClauseKind.selection => 'Selection',
    ApplicationClauseKind.declaration => 'Declaration',
    ApplicationClauseKind.rule => 'Term',
    ApplicationClauseKind.note => 'Note',
  };

  /// The name of a fact [type], as shown.
  static String typeName(ApplicationFactType type) => switch (type) {
    ApplicationFactType.name => 'name',
    ApplicationFactType.date => 'date',
    ApplicationFactType.dateRange => 'date range',
    ApplicationFactType.time => 'time',
    ApplicationFactType.amount => 'amount',
    ApplicationFactType.choices => 'choices',
  };

  /// Label of a fact's name.
  static const String factName = 'Name';

  /// Label of a fact's type.
  static const String factType = 'Type';

  /// Label of a fact's day.
  static const String day = 'Day';

  /// Label of a range's first day.
  static const String from = 'From';

  /// Label of a range's last day.
  static const String to = 'To';

  /// Label of a fact's time.
  static const String time = 'Time (24-hour)';

  /// Label of a fact's amount.
  static const String amount = 'Amount';

  /// Label of a fact's choices.
  static const String choices = 'Choices';

  /// Text of a date button with no day picked.
  static const String pickDateHint = 'Pick a date';

  /// Text of the button that adds a fact.
  static const String addFact = 'Add fact';

  /// Text of the button that adds a header item.
  static const String addHeaderItem = 'Add item';

  /// Text of the button that adds a text to a header item's line.
  static const String addToLine = 'Add to this line';

  /// Text of the button that adds an age category.
  static const String addAgeCategory = 'Add age category';

  /// Text of the button that adds a selection.
  static const String addSelection = 'Add selection';

  /// Text of the button that adds a term.
  static const String addTerm = 'Add term';

  /// Text of the button that adds a note.
  static const String addNote = 'Add note';

  /// Label of the header items.
  static const String header = 'Header items';

  /// Label of the facts.
  static const String facts = 'Facts';

  /// Label of the age categories.
  static const String ageCategories = 'Age categories';

  /// Label of the selections.
  static const String selections = 'Additional selections';

  /// Label of the terms.
  static const String terms = 'Terms';

  /// Label of the notes under the terms.
  static const String notes = 'Notes';

  /// What a fact is called in a message and above its row.
  static const String factNoun = 'Fact';

  /// What a header item is called.
  static const String headerItemNoun = 'Item';

  /// What an age category is called.
  static const String ageCategoryNoun = 'Category';

  /// What a selection is called.
  static const String selectionNoun = 'Selection';

  /// What a term is called.
  static const String termNoun = 'Term';

  /// What a note is called.
  static const String noteNoun = 'Note';

  /// The title of the [number]th item called [noun].
  static String itemTitle(String noun, int number) => '$noun $number';

  /// Label of a term's heading.
  static const String heading = 'Heading';

  /// Label of a term's or note's text.
  static const String text = 'Text';

  /// Label of a note's attribution.
  static const String attribution = 'Attribution';

  /// What an age category's name is labelled, before its language.
  static const String ageCategoryName = 'Name';

  /// Label of the tick that gives an age category birth dates.
  static const String ageLimitApplicable = 'Age limit applicable';

  /// Label of an age category's first birth date.
  static const String bornOnOrAfter = 'Born on or after';

  /// Label of an age category's last birth date.
  static const String bornOnOrBefore = 'Born on or before';

  /// Label of the genders an age category takes.
  static const String genders = 'Genders (none ticked: all)';

  /// The name of the gender stored as [value].
  static String genderName(String value) => switch (value) {
    'male' => 'Male',
    'female' => 'Female',
    _ => 'Other',
  };

  /// Label of the input of a standard label, by its English [label], in
  /// [language].
  static String labelIn(String label, String language) => '$label ($language)';

  /// Shown when a text has no English.
  static const String englishRequired = 'Needs text in English';

  /// Shown when an age category has no English name.
  static const String nameEnglishRequired = 'Needs a name in English';

  /// Shown when a standard label is emptied.
  static const String labelRequired = 'A label cannot be empty';

  /// [message] about the [number]th item called [noun].
  static String aboutItem(String noun, int number, String message) =>
      '$noun $number: $message';

  /// [message] about the part of an item labelled [part].
  static String aboutPart(String part, String message) => '$part: $message';

  /// Shown when a fact has no name.
  static const String factNameRequired = 'Each fact needs a name';

  /// Shown when a fact's [name] is not like an identifier.
  static String factNameForm(String name) =>
      '"$name" is not a fact name: use lower-case letters, digits and _, '
      'starting with a letter';

  /// Shown when two facts are named [name].
  static String factNameTwice(String name) => 'Two facts are named "$name"';

  /// Shown when a date is not picked.
  static const String dateRequired = 'Pick a date';

  /// Shown when a range lacks a day.
  static const String rangeRequired = 'Pick the first and the last day';

  /// Shown when a range ends before it starts.
  static const String rangeOrder = 'The last day is before the first';

  /// Shown when an age category's age limit has no birth date.
  static const String birthDateRequired =
      'Pick a birth date, or untick Age limit applicable';

  /// Shown when an age category's dates are the wrong way round.
  static const String birthOrder = 'The last birth date is before the first';

  /// Shown when a time is not given.
  static const String timeRequired = 'Give a time';

  /// Shown when an amount is not given.
  static const String amountRequired = 'Give a whole amount';

  /// Shown when no choice is ticked.
  static const String choicesRequired = 'Tick at least one choice';

  /// The short names of the months, January first.
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
}
