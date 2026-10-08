import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/my_event_phase.dart';
import 'cards/event_card.dart';
import 'my_events_section_header.dart';

/// Renders the grouped list of a user's events.
///
/// Pure presentation: takes a pre-filtered [events] list and a [username]
/// to pass to enrollment-aware children. Used by `EnrolledEventsBody`.
///
/// Lists the current events; [showCancelled] and [showPast] add the
/// cancelled ones and the ones that are over (club_client#88). The two
/// switches in the header report a change through the callbacks.
class MyEventsSectionBody extends StatelessWidget {
  const MyEventsSectionBody({
    required this.username,
    required this.events,
    this.onEventTap,
    this.ineligibleEventIds = const {},
    this.showCancelled = false,
    this.showPast = false,
    this.onShowCancelledChanged,
    this.onShowPastChanged,
    super.key,
  });

  final String username;
  final List<Event> events;
  final void Function(Event event)? onEventTap;

  /// Ids of the events the member no longer matches (club_client#43). They
  /// are marked, listed first under a line that counts them, and left out of
  /// the groups by type below. Empty shows the section as it always was.
  final Set<int> ineligibleEventIds;

  /// Whether the cancelled events are listed too.
  final bool showCancelled;

  /// Whether the events that are over are listed too.
  final bool showPast;

  /// Called when the Cancelled events switch is turned. Null: no switch.
  final ValueChanged<bool>? onShowCancelledChanged;

  /// Called when the Past events switch is turned. Null: no switch.
  final ValueChanged<bool>? onShowPastChanged;

  /// Heading of the cancelled events, listed after the current ones.
  static const String cancelledHeading = 'Cancelled';

  /// Heading of the events that are over, listed last.
  static const String pastHeading = 'Past';

  /// What the section reads when it has nothing to list.
  static const String emptyText = 'No enrolled events';

  /// How many of the member's events the member no longer matches, as the
  /// line above them reads.
  static String ineligibleCountText(int count) => count == 1
      ? '1 event no longer matches this member'
      : '$count events no longer match this member';

  /// Whether an event in [phase] is listed with the switches as they are.
  static bool lists(
    MyEventPhase phase, {
    required bool showCancelled,
    required bool showPast,
  }) => switch (phase) {
    MyEventPhase.current => true,
    MyEventPhase.cancelled => showCancelled,
    MyEventPhase.past => showPast,
  };

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final header = MyEventsSectionHeader(
      showCancelled: showCancelled,
      showPast: showPast,
      onShowCancelledChanged: onShowCancelledChanged,
      onShowPastChanged: onShowPastChanged,
    );
    final listed = events
        .where(
          (e) => lists(
            MyEventPhase.of(e),
            showCancelled: showCancelled,
            showPast: showPast,
          ),
        )
        .toList();

    if (listed.isEmpty) {
      return ShadCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            header,
            Row(
              spacing: 8,
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 16,
                  color: theme.colorScheme.mutedForeground,
                ),
                Text(emptyText, style: theme.textTheme.muted),
              ],
            ),
          ],
        ),
      );
    }

    final ineligible = listed
        .where((e) => ineligibleEventIds.contains(e.id))
        .toList();
    // Current events by type; then the cancelled ones and the past ones,
    // each under a heading that says what they are.
    final grouped = <String, List<Event>>{};
    for (final event in listed) {
      if (ineligibleEventIds.contains(event.id)) continue;
      final heading = switch (MyEventPhase.of(event)) {
        MyEventPhase.current => typeLabel(event.type),
        MyEventPhase.cancelled => cancelledHeading,
        MyEventPhase.past => pastHeading,
      };
      grouped.putIfAbsent(heading, () => []).add(event);
    }
    final headings = [
      for (final heading in grouped.keys)
        if (heading != cancelledHeading && heading != pastHeading) heading,
      if (grouped.containsKey(cancelledHeading)) cancelledHeading,
      if (grouped.containsKey(pastHeading)) pastHeading,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(bottom: 12), child: header),
        if (ineligible.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              ineligibleCountText(ineligible.length),
              style: theme.textTheme.small,
            ),
          ),
          for (final event in ineligible)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EventCard(
                key: ValueKey(event.id),
                eventId: event.id,
                username: username,
                memberEligible: false,
                onTap: onEventTap == null ? null : () => onEventTap!(event),
              ),
            ),
        ],
        for (final heading in headings) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              heading,
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.mutedForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final event in grouped[heading]!)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: EventCard(
                key: ValueKey(event.id),
                eventId: event.id,
                username: username,
                onTap: onEventTap == null ? null : () => onEventTap!(event),
              ),
            ),
        ],
      ],
    );
  }

  String typeLabel(EventType type) {
    return switch (type) {
      EventType.programme => 'Programmes',
      EventType.camp => 'Camps',
      EventType.oneOff => 'One-off Events',
    };
  }
}
