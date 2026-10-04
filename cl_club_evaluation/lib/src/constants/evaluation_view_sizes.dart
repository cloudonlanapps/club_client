/// Spacing, sizes and timings of the evaluation views.
abstract final class EvaluationViewSizes {
  /// Padding around a view's content.
  static const double pagePadding = 16;

  /// Gap between a view's cards and groups.
  static const double sectionGap = 16;

  /// Gap between rows of a list.
  static const double rowGap = 8;

  /// Gap between small elements (a heading and its list, buttons).
  static const double smallGap = 8;

  /// Widest a view's content grows.
  static const double maxContentWidth = 840;

  /// Widest a picker dialog grows.
  static const double dialogWidth = 560;

  /// Tallest the existing-question results grow.
  static const double resultsHeight = 360;

  /// Height of the evidence gallery.
  static const double galleryHeight = 220;

  /// Width of one evidence file in the owner's editor.
  static const double evidenceTileWidth = 220;

  /// Height of one evidence file in the owner's editor.
  static const double evidenceTileHeight = 160;

  /// Inset of an evidence file's remove action from its corner.
  static const double evidenceTileInset = 4;

  /// Padding inside a section card, as on the member profile.
  static const double cardPadding = 20;

  /// Gap under a management or info card's title, as on the profile.
  static const double cardTitleGap = 12;

  /// Gap under an editable section's title (`EditableSectionCard`).
  static const double sectionTitleGap = 16;

  /// Gap between the buttons of a management card, and between its fields.
  static const double cardItemGap = 8;

  /// How long an answer must stay unchanged before it is saved.
  static const Duration autosaveDelay = Duration(milliseconds: 700);
}
