import 'package:club_sdk_2/club_sdk_2.dart'
    show ConflictReport, EventConflictItem;

/// The three gates a schedule or staff write is checked against
/// (club_server#72): another event at the same venue, or with the same
/// organizer or coach, at the same time. The schedule clash dialog lists
/// a report's clashes under these, in this order.
enum ScheduleClashGate {
  /// Another event uses the venue at the same time.
  venue('Venue'),

  /// The organizer runs another event at the same time.
  organizer('Organizer'),

  /// A coach coaches another event at the same time.
  coach('Coach');

  const ScheduleClashGate(this.label);

  /// The heading the dialog shows over this gate's clashes.
  final String label;

  /// The clashing events [report] lists for this gate.
  List<EventConflictItem> itemsOf(ConflictReport report) => switch (this) {
    ScheduleClashGate.venue => report.venueConflicts,
    ScheduleClashGate.organizer => report.organizerConflicts,
    ScheduleClashGate.coach => report.coachConflicts,
  };
}
