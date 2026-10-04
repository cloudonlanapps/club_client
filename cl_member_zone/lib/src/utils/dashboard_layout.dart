/// Width breakpoints and panel sizing constants for the configurable
/// dashboard.
abstract class DashboardLayout {
  /// At and above this width the dashboard renders the desktop card grid.
  /// Below it, the mobile accordion is used.
  static const double mobileBreakpoint = 600;

  /// At and above this width the desktop grid uses two columns.
  static const double twoColBreakpoint = 700;

  /// At and above this width the desktop grid uses three columns.
  static const double threeColBreakpoint = 1100;

  /// Maximum height of a panel body on desktop. Bodies that overflow scroll
  /// internally so the dashboard surface itself stays a single scroll region.
  static const double desktopPanelMaxHeight = 320;

  /// Spacing between panels in the desktop grid.
  static const double gridSpacing = 12;

  /// Number of panels in the mobile accordion that start expanded on
  /// first-run for a user.
  static const int mobileInitiallyExpandedCount = 2;
}
