import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/my_event_phase.dart';
import 'my_events_section_body.dart';
import 'my_events_section_header.dart';

/// Narrows [allEvents] to those the [username] has an enrollment on, where
/// that is asked for, then renders them via `MyEventsSectionBody`.
///
/// With [enrolledOnly] (a staff profile) every event needs an enrollment:
/// public events the server returns because the user is *eligible* are
/// dropped. Without it (the member's own profile) those stay, and only the
/// cancelled and past events a switch adds need one (club_client#88): a
/// member looks back at what they were enrolled on, not at everything that
/// was once open to them.
class EnrolledEventsBody extends ConsumerWidget {
  const EnrolledEventsBody({
    required this.username,
    required this.allEvents,
    this.onEventTap,
    this.enrolledOnly = true,
    this.markIneligible = false,
    this.showCancelled = false,
    this.showPast = false,
    this.onShowCancelledChanged,
    this.onShowPastChanged,
    super.key,
  });

  final String username;
  final List<Event> allEvents;
  final void Function(Event event)? onEventTap;

  /// Whether every event needs an enrollment to be listed, or only the
  /// cancelled and past ones.
  final bool enrolledOnly;

  /// Marks the events whose enrolment is reported as no longer eligible.
  /// Read from the enrolments this widget already loads to filter the list.
  final bool markIneligible;

  /// Whether the cancelled events are listed too.
  final bool showCancelled;

  /// Whether the events that are over are listed too.
  final bool showPast;

  /// Called when the Cancelled events switch is turned.
  final ValueChanged<bool>? onShowCancelledChanged;

  /// Called when the Past events switch is turned.
  final ValueChanged<bool>? onShowPastChanged;

  /// Whether [event] is listed only if the member has an enrollment on it.
  /// Without [enrolledOnly] that is a cancelled or past event its switch
  /// adds; one the switches leave out is not looked up at all.
  bool needsEnrollment(Event event) {
    if (enrolledOnly) return true;
    final phase = MyEventPhase.of(event);
    return phase != MyEventPhase.current &&
        MyEventsSectionBody.lists(
          phase,
          showCancelled: showCancelled,
          showPast: showPast,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final enrollmentAsyncs = <int, AsyncValue<Enrollment?>>{
      for (final event in allEvents)
        if (needsEnrollment(event))
          event.id: ref.watch(
            clMyEnrollmentProvider(
              (username: username, eventId: event.id),
            ),
          ),
    };

    // A staff profile waits for every enrolment before it lists anything.
    // The member's own list is already on screen when a switch is turned,
    // so an event whose enrolment is still being read joins it when known.
    if (enrolledOnly) {
      final anyLoading = enrollmentAsyncs.values.any((a) => a.isLoading);
      if (anyLoading) {
        return const ShadCard(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final anyError = enrollmentAsyncs.values.any((a) => a.hasError);
      if (anyError) {
        return ShadCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(MyEventsSectionHeader.title, style: theme.textTheme.h4),
              const SizedBox(height: 12),
              Text('Failed to load events', style: theme.textTheme.muted),
            ],
          ),
        );
      }
    }

    final enrolled = <Event>[
      for (final event in allEvents)
        if (!enrollmentAsyncs.containsKey(event.id) ||
            enrollmentAsyncs[event.id]!.valueOrNull != null)
          event,
    ];

    final ineligibleEventIds = <int>{
      if (markIneligible)
        for (final entry in enrollmentAsyncs.entries)
          if (entry.value.valueOrNull?.eligible == false) entry.key,
    };

    return MyEventsSectionBody(
      username: username,
      events: enrolled,
      onEventTap: onEventTap,
      ineligibleEventIds: ineligibleEventIds,
      showCancelled: showCancelled,
      showPast: showPast,
      onShowCancelledChanged: onShowCancelledChanged,
      onShowPastChanged: onShowPastChanged,
    );
  }
}
