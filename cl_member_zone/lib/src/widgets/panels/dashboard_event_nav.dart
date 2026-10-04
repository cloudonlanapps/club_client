import 'package:cl_club_communication/cl_club_communication.dart';
import 'package:cl_member_zone/cl_member_zone.dart' show DashboardScreen;
import 'package:cl_member_zone/src/screens/dashboard.dart' show DashboardScreen;
import 'package:flutter/widgets.dart';

/// Inherited widget that carries dashboard navigation callbacks down to
/// individual panels and rows.
///
/// Routing belongs to `app`, not to `cl_member_zone`. The host app supplies
/// these callbacks when mounting [DashboardScreen]; widgets inside the
/// dashboard subtree (panel bodies, occurrence cards, notification rows)
/// look them up here instead of hardcoding routes.
class DashboardEventNav extends InheritedWidget {
  const DashboardEventNav({
    required this.onAdminEventTap,
    required this.onMyEventTap,
    required this.onSeeMoreNotifications,
    required this.onSeeMorePendingActions,
    required this.onNotificationDeepLink,
    required this.onHome,
    required super.child,
    super.key,
  });

  /// Navigation back to the app home / dashboard. Used by panel error
  /// placeholders so they can offer a Home action.
  final VoidCallback onHome;

  /// Tap on an event from a coach/admin-facing panel (Today's Events).
  /// The host should route to the admin event detail screen.
  final ValueChanged<int> onAdminEventTap;

  /// Tap on an event from a member-facing panel (My Events, Public Events).
  /// The host should route to the user's my-events detail screen.
  final void Function(String username, int eventId) onMyEventTap;

  /// "See more" from the Notifications panel — opens the full list screen.
  final VoidCallback onSeeMoreNotifications;

  /// "See more" from the Pending Actions panel — opens the full list.
  final VoidCallback onSeeMorePendingActions;

  /// Tap on a notification row. The host inspects the link and navigates.
  /// `null` link means the row should not navigate (e.g. broadcast text).
  final void Function(NotificationDeepLink link) onNotificationDeepLink;

  static DashboardEventNav of(BuildContext context) {
    final nav = context.dependOnInheritedWidgetOfExactType<DashboardEventNav>();
    assert(nav != null, 'No DashboardEventNav found in context');
    return nav!;
  }

  @override
  bool updateShouldNotify(DashboardEventNav oldWidget) =>
      onAdminEventTap != oldWidget.onAdminEventTap ||
      onMyEventTap != oldWidget.onMyEventTap ||
      onSeeMoreNotifications != oldWidget.onSeeMoreNotifications ||
      onSeeMorePendingActions != oldWidget.onSeeMorePendingActions ||
      onNotificationDeepLink != oldWidget.onNotificationDeepLink ||
      onHome != oldWidget.onHome;
}
