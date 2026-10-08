/// Spacing and sizes shared by the evaluation widgets.
abstract final class EvaluationSpacing {
  /// Gap between top-level layout entries, and between a section's items.
  static const double elementGap = 16;

  /// Gap inside one question: header, input, coach note, evidence.
  static const double questionGap = 8;

  /// Gap between option buttons, stars and choices.
  static const double optionGap = 8;

  /// Gap between two fields side by side in the item form, and between
  /// the checkboxes of its coach-note rule.
  static const double fieldGap = 12;

  /// Gap between a label and its field, and between outline rows.
  static const double smallGap = 6;

  /// Size of a rating star.
  static const double starSize = 28;

  /// Indent of a section's items in the outline.
  static const double indent = 20;

  /// Inner padding of an outline row.
  static const double rowPadding = 10;

  /// Width of a level's number in front of its label.
  static const double ordinalWidth = 24;

  /// Widest an item editor dialog should grow; for the host's dialog.
  static const double itemDialogWidth = 560;

  /// Opacity of a private item in a read-only evaluation.
  static const double privateOpacity = 0.5;
}
