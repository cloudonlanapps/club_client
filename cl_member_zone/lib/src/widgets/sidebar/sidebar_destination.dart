/// A place the member-zone sidebar links to.
///
/// The sidebar decides which entries a member sees, their labels and
/// icons; the host's router maps each to its route ([SidebarRoute]), so
/// no route string lives in this package.
enum SidebarDestination {
  dashboard,
  myCalendar,
  myGroups,
  myEvents,
  myAttendance,
  myReviews,
  clubCalendar,
  members,
  venues,
  groups,
  programmes,
  camps,
  oneOff,
  reviews,
  inquiries,
  siteMedia,
  clubDetails,
  profile,
  contact,
}

/// The route of [destination] for the signed-in member [username].
typedef SidebarRoute =
    String Function(SidebarDestination destination, String username);
