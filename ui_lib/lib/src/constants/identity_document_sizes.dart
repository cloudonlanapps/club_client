/// Sizes shared by the identity-document upload cards.
abstract final class IdentityDocumentSizes {
  /// Corner radius of a card.
  static const double cardRadius = 10;

  /// Gap between two cards in the row.
  static const double cardGap = 12;

  /// Gap between the row and the text under it (hint or error).
  static const double captionGap = 8;

  /// Share of the row the single add card takes when nothing is uploaded.
  static const int emptyAddCardFlex = 2;

  /// Plus icon of the add card, alone and above a label.
  static const double addIcon = 32;

  /// Plus icon of the add card when it carries a label.
  static const double addIconWithLabel = 24;

  /// Gap between an icon and the text under it.
  static const double iconTextGap = 4;

  /// Side padding of a text inside a card.
  static const double textPadding = 8;

  /// Font size of a file name inside a card.
  static const double fileNameFontSize = 11;

  /// Progress ring of an upload in flight.
  static const double spinner = 18;

  /// Stroke of the progress ring.
  static const double spinnerStroke = 2;

  /// Gap between the progress ring and the file name.
  static const double spinnerGap = 6;

  /// Distance of the remove button from the card's top right corner.
  static const double removeInset = 4;

  /// Padding around the remove button's icon.
  static const double removePadding = 4;

  /// Icon of the remove button.
  static const double removeIcon = 14;

  /// Icon shown when a preview cannot load.
  static const double placeholderIcon = 28;

  /// Opacity of the add card's fill.
  static const double addCardFill = 0.4;

  /// Opacity of a pending card's fill.
  static const double pendingCardFill = 0.6;

  /// Opacity of the remove button's disc.
  static const double removeFill = 0.85;
}
