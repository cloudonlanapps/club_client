import '../../models/application/application_fact_type.dart';
import 'application_text_mode.dart';

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

  /// Label of where a text comes from.
  static const String textFrom = 'Text from';

  /// The name of a text [mode].
  static String modeName(ApplicationTextMode mode) => switch (mode) {
    ApplicationTextMode.custom => 'Written here',
    ApplicationTextMode.fact => 'A fact',
    ApplicationTextMode.clause => 'A library clause',
  };

  /// Label of a fact picker.
  static const String fact = 'Fact';

  /// Hint of a fact picker with none chosen.
  static const String chooseFactHint = 'Pick a fact';

  /// Label of a clause picker.
  static const String clause = 'Clause';

  /// Hint of a clause picker with none chosen.
  static const String chooseClauseHint = 'Pick a clause';

  /// Label of the fact filling [gap], which takes a [type].
  static String gapLabel(String gap, ApplicationFactType type) =>
      '{$gap}: ${typeName(type)}';

  /// The name of a fact [type], as shown.
  static String typeName(ApplicationFactType type) => switch (type) {
    ApplicationFactType.name => 'name',
    ApplicationFactType.date => 'date',
    ApplicationFactType.dateRange => 'date range',
    ApplicationFactType.time => 'time',
    ApplicationFactType.amount => 'amount',
    ApplicationFactType.choices => 'choices',
  };

  /// A fact named [name], of [type], as a picker lists it.
  static String factOption(String name, ApplicationFactType? type) =>
      type == null ? name : '$name (${typeName(type)})';

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

  /// Shown when no fact is chosen.
  static const String chooseFact = 'Choose a fact';

  /// Shown when no clause is chosen.
  static const String chooseClause = 'Choose a clause';

  /// Shown for a fact the template does not have.
  static String noSuchFact(String name) => 'There is no fact "$name"';

  /// Shown for a clause the library does not have.
  static String noSuchClause(String id) => 'The library has no clause "$id"';

  /// Shown for a clause of another kind.
  static String wrongKind(String id) => '"$id" cannot be used here';

  /// Shown when [gap] has no fact.
  static String gapUnbound(String gap) => 'Choose a fact for {$gap}';

  /// Shown when [gap] has a [fact] of another type than its [type].
  static String gapWrongType(
    String gap,
    String fact,
    ApplicationFactType type,
  ) => 'The fact "$fact" is not a ${typeName(type)}, which {$gap} needs';

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
