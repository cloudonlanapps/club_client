import 'package:cl_club_events/cl_club_events.dart';
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/public_events.dart';
import '../../providers/selected_day.dart';
import 'dashboard_event_nav.dart';
import 'shared/day_occurrences_list.dart';

/// Body of the Public Events dashboard panel.
class PublicEventsPanelBody extends ConsumerWidget {
  const PublicEventsPanelBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const SizedBox(
        height: publicEventsBodyHeight,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final selected = ref.watch(selectedDayProvider);
    final range = (
      from: startOfDayLocal(selected).toUtc(),
      to: endOfDayLocal(selected).toUtc(),
    );

    final nav = DashboardEventNav.of(context);
    return SizedBox(
      height: publicEventsBodyHeight,
      child: DayOccurrencesList(
        source: todayPublicOccurrencesProvider(user.username),
        emptyText: 'No public events',
        errorPrefix: 'Could not load public events',
        rowBuilder: (occurrence) => OccurrenceCard(
          eventId: occurrence.eventId,
          occurrenceTime: occurrence.originalStartTimeUtc,
          range: range,
          username: user.username,
          showRecurrence: true,
          showVenue: true,
          onTap: () => nav.onMyEventTap(user.username, occurrence.eventId),
        ),
      ),
    );
  }
}

const double publicEventsBodyHeight = 296;
