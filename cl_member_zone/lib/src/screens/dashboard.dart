import 'package:cl_club_communication/cl_club_communication.dart';
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show clubEventTypesProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show EventType;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;
import 'package:ui_lib/ui_lib.dart' show ErrorView;

import '../providers/dashboard_prefs.dart';
import '../theme/layout_constants.dart';
import '../utils/dashboard_layout.dart';
import '../utils/panel_registry.dart';
import '../widgets/admin_quick_actions_strip.dart';
import '../widgets/dashboard_desktop_grid.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_mobile_accordion.dart';
import '../widgets/empty_dashboard.dart';
import '../widgets/panels/dashboard_event_nav.dart';
import '../widgets/quick_action_tile.dart';

/// Configurable dashboard surface.
///
/// Layout switches between a desktop card grid and a mobile accordion at
/// [DashboardLayout.mobileBreakpoint]. Visible panels and their order come
/// from the static panel registry, filtered by the user's role flags from
/// [authStateProvider]. Selection and mobile expansion state are owned by
/// [dashboardPrefsProvider].
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({
    required this.onAdminEventTap,
    required this.onMyEventTap,
    required this.onSeeMoreNotifications,
    required this.onSeeMorePendingActions,
    required this.onNotificationDeepLink,
    required this.onCreateUser,
    required this.onCreateGroup,
    required this.onCreateEvent,
    required this.onAnnouncement,
    required this.onAuditLog,
    required this.onHome,
    super.key,
  });

  /// Navigation back to the app home (typically a refresh of the
  /// current dashboard).
  final VoidCallback onHome;

  /// Invoked when the user taps an event in the admin/coach Today's Events
  /// panel. The host routes to the admin event detail screen.
  final ValueChanged<int> onAdminEventTap;

  /// Invoked when the user taps an event in My Events or Public Events
  /// panels. The host routes to the user's my-events detail screen.
  final void Function(String username, int eventId) onMyEventTap;

  /// Invoked when the user taps "See more" in the Notifications panel.
  /// The host routes to the full notifications list.
  final VoidCallback onSeeMoreNotifications;

  /// Invoked when the user taps "See more" in the Pending Actions panel.
  /// The host routes to the full pending-actions list.
  final VoidCallback onSeeMorePendingActions;

  /// Invoked when the user taps a notification row; the host inspects the
  /// link and navigates accordingly.
  final void Function(NotificationDeepLink link) onNotificationDeepLink;

  /// Admin Quick Actions strip — Create User tile.
  final VoidCallback onCreateUser;

  /// Admin Quick Actions strip — Create Group tile.
  final VoidCallback onCreateGroup;

  /// Admin Quick Actions strip — Create Event tile: opens the create flow
  /// for the chosen event type.
  final ValueChanged<EventType> onCreateEvent;

  /// Admin Quick Actions strip — Announcement tile (pushes Broadcast screen).
  final VoidCallback onAnnouncement;

  /// Opens the super-admin global audit-log feed (issue #207). Rendered only
  /// for super-admins.
  final VoidCallback onAuditLog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final user = auth.valueOrNull;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final isAdmin = user.roles.isAdmin || user.isSuperAdmin;
    final isSuperAdmin = user.isSuperAdmin;
    final isCoach = user.roles.isCoach;
    final allowed = visiblePanelsFor(isAdmin: isAdmin, isCoach: isCoach);

    final prefsAsync = ref.watch(dashboardPrefsProvider);

    return DashboardEventNav(
      onAdminEventTap: onAdminEventTap,
      onMyEventTap: onMyEventTap,
      onSeeMoreNotifications: onSeeMoreNotifications,
      onSeeMorePendingActions: onSeeMorePendingActions,
      onNotificationDeepLink: onNotificationDeepLink,
      onHome: onHome,
      child: Padding(
        padding: LayoutConstants.contentPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isAdmin) ...[
              AdminQuickActionsStrip(
                onCreateUser: onCreateUser,
                onCreateGroup: onCreateGroup,
                onCreateEvent: onCreateEvent,
                onAnnouncement: onAnnouncement,
                eventTypes: ref.watch(clubEventTypesProvider),
              ),
              LayoutConstants.sectionGap,
            ],
            if (isSuperAdmin) ...[
              QuickActionTile(
                icon: LucideIcons.scrollText,
                label: 'Audit Log',
                onTap: onAuditLog,
              ),
              LayoutConstants.sectionGap,
            ],
            DashboardHeader(allowed: allowed),
            LayoutConstants.sectionGap,
            Expanded(
              child: prefsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorView(
                  title: 'Could not load dashboard preferences',
                  errorCode: '$e',
                  onHome: onHome,
                  onRetry: () => ref.invalidate(dashboardPrefsProvider),
                ),
                data: (prefs) {
                  final visible = allowed
                      .where((p) => prefs.selected.contains(p.id))
                      .toList(growable: false);
                  if (visible.isEmpty) {
                    return const EmptyDashboard();
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth <
                          DashboardLayout.mobileBreakpoint) {
                        return DashboardMobileAccordion(
                          visible: visible,
                          expanded: prefs.expandedOnMobile,
                        );
                      }
                      return DashboardDesktopGrid(
                        visible: visible,
                        width: constraints.maxWidth,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
