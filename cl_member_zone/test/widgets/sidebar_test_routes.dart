import 'package:cl_member_zone/src/widgets/sidebar/sidebar_destination.dart';

/// Sidebar routes for the sidebar's tests: the app's member-zone routes
/// without their `/memberzone` prefix.
String testSidebarRoute(SidebarDestination destination, String username) =>
    switch (destination) {
      SidebarDestination.dashboard => '/',
      SidebarDestination.myCalendar => '/my-events/$username/calendar',
      SidebarDestination.myGroups => '/my-groups/$username',
      SidebarDestination.myEvents => '/my-events/$username',
      SidebarDestination.applications => '/applications',
      SidebarDestination.myAttendance => '/my-events/$username/attendance',
      SidebarDestination.myReviews => '/reviews/mine',
      SidebarDestination.clubCalendar => '/events/calendar',
      SidebarDestination.members => '/users',
      SidebarDestination.venues => '/venues',
      SidebarDestination.groups => '/groups',
      SidebarDestination.programmes => '/events/programmes',
      SidebarDestination.camps => '/events/camps',
      SidebarDestination.oneOff => '/events/one-off',
      SidebarDestination.reviews => '/reviews',
      SidebarDestination.inquiries => '/inquiries',
      SidebarDestination.siteMedia => '/site-media',
      SidebarDestination.clubDetails => '/club-details',
      SidebarDestination.profile => '/profile',
      SidebarDestination.contact => '/contact',
    };
