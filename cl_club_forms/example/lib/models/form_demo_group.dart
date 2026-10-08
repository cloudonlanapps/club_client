/// The families the sidebar groups the forms by, in the order shown.
enum FormDemoGroup {
  /// Signing in and signing up.
  account('Account'),

  /// A member's record and its sections.
  users('Users'),

  /// Creating an event and its sections.
  events('Events'),

  /// When an event runs.
  schedules('Schedules'),

  /// Credit packages.
  credit('Credit'),

  /// Groups of members.
  groups('Groups'),

  /// Venues.
  venues('Venues'),

  /// The club's own details.
  clubIdentity('Club identity'),

  /// What a visitor of the club's website fills.
  website('Website');

  const FormDemoGroup(this.title);

  /// The heading shown in the sidebar.
  final String title;
}
