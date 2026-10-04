import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/dashboard_panel_id.dart';
import '../models/panel_descriptor.dart';
import '../models/panel_role.dart';
import '../widgets/panels/my_events_panel_body.dart';
import '../widgets/panels/notifications_panel_body.dart';
import '../widgets/panels/pending_actions_panel_body.dart';
import '../widgets/panels/public_events_panel_body.dart';
import '../widgets/panels/todays_events_panel_body.dart';

/// Static registry of every dashboard panel.
///
/// Order in this list is the fixed display order on the dashboard surface.
const List<PanelDescriptor> kPanels = [
  PanelDescriptor(
    id: DashboardPanelId.todaysEvents,
    title: "Today's Events",
    icon: LucideIcons.calendarClock,
    requiredRole: PanelRole.coachOrAbove,
    builder: buildTodaysEventsPanelBody,
  ),
  PanelDescriptor(
    id: DashboardPanelId.myEvents,
    title: 'My Events',
    icon: LucideIcons.calendarHeart,
    requiredRole: PanelRole.any,
    builder: buildMyEventsPanelBody,
  ),
  PanelDescriptor(
    id: DashboardPanelId.publicEvents,
    title: 'Public Events',
    icon: LucideIcons.calendarRange,
    requiredRole: PanelRole.any,
    builder: buildPublicEventsPanelBody,
  ),
  PanelDescriptor(
    id: DashboardPanelId.notifications,
    title: 'Notifications',
    icon: LucideIcons.bell,
    requiredRole: PanelRole.any,
    builder: buildNotificationsPanelBody,
  ),
  PanelDescriptor(
    id: DashboardPanelId.pendingActions,
    title: 'Pending Actions',
    icon: LucideIcons.listChecks,
    requiredRole: PanelRole.any,
    builder: buildPendingActionsPanelBody,
  ),
];

Widget buildTodaysEventsPanelBody(BuildContext context) =>
    const TodaysEventsPanelBody();
Widget buildMyEventsPanelBody(BuildContext context) =>
    const MyEventsPanelBody();
Widget buildPublicEventsPanelBody(BuildContext context) =>
    const PublicEventsPanelBody();
Widget buildNotificationsPanelBody(BuildContext context) =>
    const NotificationsPanelBody();
Widget buildPendingActionsPanelBody(BuildContext context) =>
    const PendingActionsPanelBody();

/// Returns the panels visible to a user with the given role flags, in fixed
/// display order.
List<PanelDescriptor> visiblePanelsFor({
  required bool isAdmin,
  required bool isCoach,
}) {
  return kPanels
      .where((p) {
        switch (p.requiredRole) {
          case PanelRole.any:
            return true;
          case PanelRole.coachOrAbove:
            return isAdmin || isCoach;
          case PanelRole.adminOnly:
            return isAdmin;
        }
      })
      .toList(growable: false);
}

/// Returns the descriptor for [id]. Throws if [id] is not in [kPanels].
PanelDescriptor descriptorFor(DashboardPanelId id) =>
    kPanels.firstWhere((p) => p.id == id);
