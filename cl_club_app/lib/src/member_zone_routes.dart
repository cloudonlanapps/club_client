import 'package:cl_member_zone/cl_member_zone.dart' show SidebarDestination;

import 'utils/router_helpers.dart';

/// The route of each member-zone sidebar entry for the signed-in member
/// [username]. The router owns these paths; the sidebar only names its
/// destinations (#204).
String memberZoneSidebarRoute(
  SidebarDestination destination,
  String username,
) => switch (destination) {
  SidebarDestination.dashboard => '/',
  SidebarDestination.myCalendar => '/memberzone/my-events/$username/calendar',
  SidebarDestination.myGroups => '/memberzone/my-groups/$username',
  SidebarDestination.myEvents => '/memberzone/my-events/$username',
  SidebarDestination.applications => applicationsPath,
  SidebarDestination.myAttendance =>
    '/memberzone/my-events/$username/attendance',
  SidebarDestination.myReviews => '/memberzone/reviews/mine',
  SidebarDestination.clubCalendar => '/memberzone/events/calendar',
  SidebarDestination.members => '/memberzone/users',
  SidebarDestination.venues => '/memberzone/venues',
  SidebarDestination.groups => '/memberzone/groups',
  SidebarDestination.programmes => '/memberzone/events/programmes',
  SidebarDestination.camps => '/memberzone/events/camps',
  SidebarDestination.oneOff => '/memberzone/events/one-off',
  SidebarDestination.reviews => '/memberzone/reviews',
  SidebarDestination.inquiries => '/memberzone/inquiries',
  SidebarDestination.siteMedia => '/memberzone/site-media',
  SidebarDestination.clubDetails => '/memberzone/club-details',
  SidebarDestination.profile => '/memberzone/profile',
  SidebarDestination.contact => '/memberzone/contact',
};
