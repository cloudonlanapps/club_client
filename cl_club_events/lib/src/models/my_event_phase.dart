import 'package:club_sdk_2/club_sdk_2.dart';

import '../providers/event_display_status.dart';
import 'event_display_status.dart';

/// Where an event stands for the Events section of a profile
/// (club_client#88): the section lists the [current] ones, and has a switch
/// for the [cancelled] ones and one for the [past] ones.
enum MyEventPhase {
  /// Running or still to start, a cutoff that is still ahead included.
  current,

  /// Over: a programme whose cutoff has passed, a camp or one-off whose last
  /// occurrence has.
  past,

  /// A camp or one-off whose cutoff has passed: it was cancelled or dropped.
  cancelled;

  /// The phase of [event] at [now] (default: the present).
  ///
  /// The same rule as the caption of an event's card
  /// ([computeDisplayStatus]), read from the event alone: its schedules only
  /// tell "ongoing" from "coming soon", which are both [current].
  static MyEventPhase of(Event event, {DateTime? now}) =>
      switch (computeDisplayStatus(event, const [], now: now)) {
        EventDisplayStatus.cancelled => MyEventPhase.cancelled,
        EventDisplayStatus.ended => MyEventPhase.past,
        EventDisplayStatus.ongoing ||
        EventDisplayStatus.comingSoon => MyEventPhase.current,
      };
}
