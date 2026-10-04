import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'cards/event_card.dart';

/// Renders the grouped list of a user's events.
///
/// Pure presentation: takes a pre-filtered [events] list and a [username]
/// to pass to enrollment-aware children. Used by `MyEventsSection` and
/// `EnrolledEventsBody`.
class MyEventsSectionBody extends StatelessWidget {
  const MyEventsSectionBody({
    required this.username,
    required this.events,
    this.onEventTap,
    super.key,
  });

  final String username;
  final List<Event> events;
  final void Function(Event event)? onEventTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final activeEvents = events
        .where((e) => e.status == EventStatus.active)
        .toList();

    if (activeEvents.isEmpty) {
      return ShadCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Events', style: theme.textTheme.h4),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  LucideIcons.calendar,
                  size: 16,
                  color: theme.colorScheme.mutedForeground,
                ),
                const SizedBox(width: 8),
                Text('No enrolled events', style: theme.textTheme.muted),
              ],
            ),
          ],
        ),
      );
    }

    final grouped = <EventType, List<Event>>{};
    for (final event in activeEvents) {
      grouped.putIfAbsent(event.type, () => []).add(event);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text('Events', style: theme.textTheme.h4),
        ),
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              typeLabel(entry.key),
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.mutedForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final event in entry.value)
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
