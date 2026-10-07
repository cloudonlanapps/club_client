/// The demo's measures.
abstract final class DemoSizes {
  /// Below this width the sidebar is a drawer.
  static const double drawerBreakpoint = 768;

  /// Width of the sidebar.
  static const double sidebarWidth = 280;

  /// Height of the bar above the main view.
  static const double topBarHeight = 56;

  /// Widest the card of an ordinary form grows.
  static const double formMaxWidth = 560;

  /// Widest the card of a form with a two-column grid grows.
  static const double wideFormMaxWidth = 760;

  /// Around the main view, inside the card and inside the bars.
  static const double pagePadding = 16;

  /// Between the controls of the top bar.
  static const double topBarGap = 8;

  /// Small gaps: under a heading, between two sidebar items.
  static const double smallGap = 2;

  /// Corner radius of the card and of the sidebar items.
  static const double radius = 8;

  /// Font size of a sidebar item.
  static const double sidebarItemFontSize = 13;

  /// Font size of a group heading in the sidebar.
  static const double sidebarGroupFontSize = 10;

  /// Letter spacing of a group heading in the sidebar.
  static const double sidebarGroupLetterSpacing = 0.8;

  /// Horizontal inset of a sidebar item, outside and inside.
  static const double sidebarItemInset = 8;

  /// Vertical inset of a sidebar item's text.
  static const double sidebarItemVerticalInset = 8;

  /// Above a group heading in the sidebar.
  static const double sidebarGroupTopInset = 12;

  /// Opacity of the selected sidebar item's background.
  static const double selectedAlpha = 0.1;
}
