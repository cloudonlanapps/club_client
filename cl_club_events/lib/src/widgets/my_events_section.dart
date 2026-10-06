import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'enrolled_events_body.dart';
import 'my_events_section_body.dart';

/// Section displaying a user's enrolled events, grouped by event type.
///
/// Takes a [username] and watches [clMyEventsMasterProvider] to display
/// the user's subscribed events. Loosely coupled — does not assume context
/// (works in profile view, dashboard, or standalone).
///
/// When [enrolledOnly] is true, public events the user is eligible for but
/// has no enrollment on are filtered out. Use this in admin contexts where
/// the section should reflect only events specific to the target user.
///
/// [markIneligible] is set by the host where staff look at another member
/// (the staff profile). It needs [enrolledOnly].
class MyEventsSection extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final masterAsync = ref.watch(clMyEventsMasterProvider(username));

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
            Text('Events', style: theme.textTheme.h4),
            const SizedBox(height: 12),
            Text('Failed to load events', style: theme.textTheme.muted),
          ],
        ),
      ),
      data: (events) {
        if (enrolledOnly) {
          return EnrolledEventsBody(
            username: username,
            allEvents: events,
            onEventTap: onEventTap,
            markIneligible: markIneligible,
          );
        }
        return MyEventsSectionBody(
          username: username,
          events: events,
          onEventTap: onEventTap,
        );
      },
    );
  }
}
