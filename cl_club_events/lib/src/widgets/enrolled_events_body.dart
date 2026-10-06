import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'my_events_section_body.dart';

/// Filters [allEvents] to only those the [username] has an enrollment on,
/// then renders them via `MyEventsSectionBody`.
///
/// Public events the server returns because the user is *eligible* but has
/// no enrollment are dropped. Used by `MyEventsSection` when
/// `enrolledOnly` is true.
class EnrolledEventsBody extends ConsumerWidget {
  const EnrolledEventsBody({
    required this.username,
    required this.allEvents,
    this.onEventTap,
    this.markIneligible = false,
    super.key,
  });

  final String username;
  final List<Event> allEvents;
  final void Function(Event event)? onEventTap;

  /// Marks the events whose enrolment is reported as no longer eligible.
  /// Read from the enrolments this widget already loads to filter the list.
  final bool markIneligible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final enrollmentAsyncs = [
      for (final event in allEvents)
        ref.watch(
          clMyEnrollmentProvider(
            (username: username, eventId: event.id),
          ),
        ),
    ];

    final anyLoading = enrollmentAsyncs.any((a) => a.isLoading);
    if (anyLoading) {
      return const ShadCard(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final anyError = enrollmentAsyncs.any((a) => a.hasError);
    if (anyError) {
      return ShadCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Events', style: theme.textTheme.h4),
            const SizedBox(height: 12),
            Text('Failed to load events', style: theme.textTheme.muted),
          ],
        ),
      );
    }

    final enrolled = <Event>[
      for (var i = 0; i < allEvents.length; i++)
        if (enrollmentAsyncs[i].valueOrNull != null) allEvents[i],
    ];

    final ineligibleEventIds = <int>{
      if (markIneligible)
        for (var i = 0; i < allEvents.length; i++)
          if (enrollmentAsyncs[i].valueOrNull?.eligible == false)
            allEvents[i].id,
    };

    return MyEventsSectionBody(
      username: username,
      events: enrolled,
      onEventTap: onEventTap,
      ineligibleEventIds: ineligibleEventIds,
    );
  }
}
