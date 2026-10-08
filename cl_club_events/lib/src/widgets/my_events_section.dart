import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'enrolled_events_body.dart';
import 'my_events_section_header.dart';

/// Section displaying a user's enrolled events, grouped by event type.
///
/// Takes a [username] and watches [clMyEventsMasterProvider] to display
/// the user's subscribed events. Loosely coupled — does not assume context
/// (works in profile view, dashboard, or standalone).
///
/// It lists the current events and holds two switches, both off to start
/// with: one adds the cancelled events, one the events that are over, each
/// only where the user has an enrollment (club_client#88).
///
/// When [enrolledOnly] is true, public events the user is eligible for but
/// has no enrollment on are filtered out. Use this in admin contexts where
/// the section should reflect only events specific to the target user.
///
/// [markIneligible] is set by the host where staff look at another member
/// (the staff profile). It needs [enrolledOnly].
class MyEventsSection extends ConsumerStatefulWidget {
  const MyEventsSection({
    required this.username,
    this.onEventTap,
    this.enrolledOnly = false,
    this.markIneligible = false,
    super.key,
  }) : assert(
         enrolledOnly || !markIneligible,
         'markIneligible needs enrolledOnly: the mark is read from the '
         "member's enrolments, which only that mode loads for the section.",
       );

  final String username;
  final void Function(Event event)? onEventTap;
  final bool enrolledOnly;

  /// Marks the events whose enrolment the server reports as no longer
  /// eligible, lists them first and counts them (club_client#43). For staff
  /// looking at another member; a member's own views leave it false.
  final bool markIneligible;

  @override
  ConsumerState<MyEventsSection> createState() => MyEventsSectionState();
}

/// Holds what the two switches of [MyEventsSection] are set to.
class MyEventsSectionState extends ConsumerState<MyEventsSection> {
  /// Whether the cancelled events are listed too.
  bool showCancelled = false;

  /// Whether the events that are over are listed too.
  bool showPast = false;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final masterAsync = ref.watch(clMyEventsMasterProvider(widget.username));

    return masterAsync.when(
      loading: () => const ShadCard(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => ShadCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(MyEventsSectionHeader.title, style: theme.textTheme.h4),
            const SizedBox(height: 12),
            Text('Failed to load events', style: theme.textTheme.muted),
          ],
        ),
      ),
      data: (events) => EnrolledEventsBody(
        username: widget.username,
        allEvents: events,
        onEventTap: widget.onEventTap,
        enrolledOnly: widget.enrolledOnly,
        markIneligible: widget.markIneligible,
        showCancelled: showCancelled,
        showPast: showPast,
        onShowCancelledChanged: (value) =>
            setState(() => showCancelled = value),
        onShowPastChanged: (value) => setState(() => showPast = value),
      ),
    );
  }
}
