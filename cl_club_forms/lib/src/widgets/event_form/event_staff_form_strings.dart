/// The text `EventStaffForm` shows.
abstract final class EventStaffFormStrings {
  /// Label of the organizer row.
  static const String organizerLabel = 'Organizer';

  /// Label of the coaches row.
  static const String coachesLabel = 'Coaches';

  /// Shown in place of the organizer while the event has none.
  static const String unassigned = 'Unassigned';

  /// Shown in place of the coach list while it is empty.
  static const String noCoaches = 'No coaches assigned.';

  /// The action that picks another organizer.
  static const String transfer = 'Transfer';

  /// The action that picks more coaches.
  static const String addCoaches = 'Add coaches';

  /// The action that takes back a coach's staged removal.
  static const String undo = 'Undo';

  /// What precedes a username where one is shown.
  static const String usernamePrefix = '@';

  /// What saving does to a programme, for the session written as [from].
  static String effectLine(String from) =>
      'Sessions before $from keep the present organizer and coaches; '
      'sessions from it have the new ones.';
}
