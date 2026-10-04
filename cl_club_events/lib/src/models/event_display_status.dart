/// Display status for events in the admin view.
///
/// Derived from the event, its schedules and rrule expansion
/// (club_core#16): there is no whole-event "cancelled" any more. A
/// terminated programme, a cancelled camp or a dropped one-off keeps running
/// until its cutoff (`Event.untilTimeUtc`), and only then reads as ended or
/// cancelled.
///
/// - [ongoing]: Occurrences are happening or scheduled, including a bounded
///   event whose cutoff is still ahead.
/// - [comingSoon]: No schedule has started yet.
/// - [ended]: Programme whose cutoff has passed; camp / one-off whose last
///   occurrence is in the past.
/// - [cancelled]: Camp / one-off whose cutoff has passed (an intentional
///   cancellation or drop). Never used for programmes.
enum EventDisplayStatus { ongoing, comingSoon, ended, cancelled }

/// Canonical, user-visible label for [EventDisplayStatus]. Shared by the
/// EventCard caption, the event-details audit card, and any future
/// status-aware surface so wording stays consistent across the app.
String eventDisplayStatusLabel(EventDisplayStatus status) {
  return switch (status) {
    EventDisplayStatus.ongoing => 'Ongoing',
    EventDisplayStatus.comingSoon => 'Coming Soon',
    EventDisplayStatus.ended => 'Ended',
    EventDisplayStatus.cancelled => 'Cancelled',
  };
}
