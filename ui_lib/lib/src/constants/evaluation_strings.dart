/// Every user-facing string of the evaluation widgets, in evaluation terms.
abstract final class EvaluationStrings {
  // Item kinds.

  /// `EvaluationItemKind.rating`.
  static const String kindRating = 'Rating';

  /// `EvaluationItemKind.yesNo`.
  static const String kindYesNo = 'Yes / No';

  /// `EvaluationItemKind.singleChoice`.
  static const String kindSingleChoice = 'Single choice';

  /// `EvaluationItemKind.multipleChoice`.
  static const String kindMultipleChoice = 'Multiple choice';

  /// `EvaluationItemKind.number`.
  static const String kindNumber = 'Number';

  /// `EvaluationItemKind.qa`.
  static const String kindQa = 'Q & A';

  /// `EvaluationItemKind.info`.
  static const String kindInfo = 'Info text';

  // Rating styles.

  /// `EvaluationRatingStyle.stars`.
  static const String styleStars = 'Stars';

  /// `EvaluationRatingStyle.range`.
  static const String styleRange = 'Range';

  /// `EvaluationRatingStyle.levels`.
  static const String styleLevels = 'Labelled levels';

  // Answer inputs.

  /// A range rating with no value yet.
  static const String notRated = 'Not rated';

  /// Clears an answer.
  static const String clear = 'Clear';

  /// Default label of a yes / no question's true answer.
  static const String yes = 'Yes';

  /// Default label of a yes / no question's false answer.
  static const String no = 'No';

  /// Number text that does not parse.
  static const String notANumber = 'Enter a number.';

  /// Placeholder of a number answer.
  static const String numberPlaceholder = 'Enter a number';

  /// Steps a long range rating down.
  static const String decrease = 'Decrease';

  /// Steps a long range rating up.
  static const String increase = 'Increase';

  /// Joins a range's bounds, e.g. "1–20".
  static const String rangeSeparator = '–';

  /// Placeholder of a written answer.
  static const String answerPlaceholder = 'Write the answer (markdown)';

  /// The coach note's label.
  static const String coachNote = 'Coach note';

  /// Reminds the coach who reads the note.
  static const String coachNoteHint = 'The member sees this note.';

  /// Placeholder of the coach note.
  static const String coachNotePlaceholder = 'Add a note for the member';

  /// Semantic label of the star worth a value, e.g. "Rate 3".
  static const String ratePrefix = 'Rate';

  // Item form.

  /// The question text field.
  static const String question = 'Question';

  /// The info text field.
  static const String infoText = 'Text (markdown)';

  /// The required switch.
  static const String required = 'Required';

  /// The private switch.
  static const String private = 'Private';

  /// Explains the private switch.
  static const String privateHint =
      'Private items and their answers are never shown to the member.';

  /// The evidence switch.
  static const String allowEvidence = 'Allow evidence';

  /// Explains the evidence switch.
  static const String allowEvidenceHint = 'Images, videos and PDFs.';

  /// The comment area switch.
  static const String commentArea = 'Comment area';

  /// Explains the comment area switch.
  static const String commentAreaHint = 'A coach note under the answer.';

  /// The answers that require a coach note.
  static const String requireCommentFor = 'Require a coach note for';

  /// The rating style select.
  static const String scale = 'Scale';

  /// Lowest value of a stars or range scale.
  static const String rateMin = 'Lowest';

  /// Highest value of a stars or range scale.
  static const String rateMax = 'Highest';

  /// The labelled levels list.
  static const String levels = 'Levels';

  /// Adds a level.
  static const String level = 'Level';

  /// The choices list.
  static const String choices = 'Choices';

  /// Adds a choice.
  static const String choice = 'Choice';

  /// Placeholder of a level or choice label.
  static const String labelPlaceholder = 'Label';

  /// Label of the true answer of a yes / no question.
  static const String labelTrue = 'Label for Yes';

  /// Label of the false answer of a yes / no question.
  static const String labelFalse = 'Label for No';

  // Item form validation.

  /// Missing question.
  static const String questionRequired = 'Enter the question.';

  /// Missing info text.
  static const String infoTextRequired = 'Enter the text.';

  /// A scale bound that is not a whole number.
  static const String wholeNumber = 'Enter a whole number.';

  /// A scale whose highest value is not above its lowest.
  static const String rangeOrder =
      'The highest value must be above the lowest.';

  /// No levels.
  static const String levelsRequired = 'Add at least one level.';

  /// A level without a label.
  static const String levelLabelRequired = 'Every level needs a label.';

  /// Two levels with one label.
  static const String levelsDistinct = 'Level labels must differ.';

  /// No choices.
  static const String choicesRequired = 'Add at least one choice.';

  /// A choice whose label gives no value.
  static const String choiceLabelRequired =
      'Every choice needs a label with a letter or digit.';

  /// Two choices with one value.
  static const String choicesDistinct = 'Choice labels must differ.';

  /// A note rule without the comment area.
  static const String ruleNeedsCommentArea =
      'A coach note can be required only with the comment area on.';

  // Layout editor.

  /// A titled group of items.
  static const String section = 'Section';

  /// Copies a question of another template.
  static const String existingQuestion = 'Existing question';

  /// Shows the reorder arrows.
  static const String sort = 'Sort';

  /// Moves a row up.
  static const String moveUp = 'Move up';

  /// Moves a row down.
  static const String moveDown = 'Move down';

  /// Removes a row.
  static const String delete = 'Delete';

  /// Semantic label of the add bar, which shows only a "+".
  static const String addItem = 'Add an item';

  /// Semantic label of a section's own "+".
  static const String addToSection = 'Add to this section';

  /// An empty section in the outline.
  static const String emptySection = 'No items yet';

  // Template create form.

  /// The template name field.
  static const String templateName = 'Template name';

  /// Placeholder of the template name.
  static const String templateNamePlaceholder = 'e.g., Skating assessment';

  /// The layout field.
  static const String items = 'Items';

  /// A template with no question.
  static const String questionNeeded = 'Add at least one question.';

  /// A section without a title.
  static const String sectionTitleRequired = 'Every section needs a title.';

  // Fill form and read body.

  /// Appended to a required question.
  static const String requiredMarker = '*';

  /// Marks a private question for the coach.
  static const String privateMarker = 'Private: not shown to the member';

  /// A required question without an answer.
  static const String answerRequired = 'An answer is required.';

  /// An answer that requires a coach note, without one.
  static const String noteRequired =
      'A coach note is required for this answer.';

  /// An item the server reports as incomplete.
  static const String incomplete = 'Complete this answer.';

  /// A question without an answer, read-only.
  static const String notAnswered = 'Not answered';

  /// Joins the labels of a multiple-choice answer.
  static const String choiceSeparator = ', ';

  /// Separates a range value from its maximum, e.g. "7 / 10".
  static const String outOf = ' / ';

  /// Separates the parts of an outline row's caption, e.g. "Rating · Private".
  static const String captionSeparator = ' · ';

  // Starting an evaluation, and its review period.

  /// The start form's template field.
  static const String template = 'Template';

  /// The template field before a choice.
  static const String templatePlaceholder = 'Choose a template';

  /// No template chosen.
  static const String templateRequired = 'Choose a template.';

  /// The start form's member field.
  static const String member = 'Member';

  /// The member field before a choice.
  static const String memberPlaceholder = 'Choose a member';

  /// No member chosen.
  static const String memberRequired = 'Choose a member.';

  /// The start form's event field.
  static const String event = 'Event';

  /// An evaluation about no one event.
  static const String general = 'General';

  /// The start of the review period.
  static const String periodStart = 'Period from';

  /// The end of the review period.
  static const String periodEnd = 'Period to';

  /// A period date left empty.
  static const String periodNone = 'No date';

  /// Only one end of the period given.
  static const String periodBoth = 'Give both dates, or neither.';

  /// A period ending before it starts.
  static const String periodOrder =
      'The period must end on or after its start.';

  /// A period ending after today.
  static const String periodFuture = 'The period must end today or earlier.';
}
