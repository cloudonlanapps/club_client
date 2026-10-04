import 'package:cl_club_events/cl_club_events.dart';
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/selected_day.dart';
import '../../providers/today_all_occurrences.dart';
import 'dashboard_event_nav.dart';
import 'shared/day_occurrences_list.dart';

/// Body of the Today's Events dashboard panel (admin/coach only).
///
/// Lists every club-wide occurrence for the selected day. The panel
/// passes IDs and the day's `(from, to)` range to each card; the card
/// resolves the occurrence and event itself, derives its caption, and
/// mounts the right action resolver.
class TodaysEventsPanelBody extends ConsumerWidget {
  const TodaysEventsPanelBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const SizedBox(
        height: todaysEventsBodyHeight,
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
      height: todaysEventsBodyHeight,
      child: DayOccurrencesList(
        source: todayAllOccurrencesProvider,
        emptyText: 'No events today',
        errorPrefix: "Could not load today's events",
        rowBuilder: (occurrence) => OccurrenceCard(
          eventId: occurrence.eventId,
          occurrenceTime: occurrence.originalStartTimeUtc,
          range: range,
          showRecurrence: true,
          showVenue: true,
          onTap: () => nav.onAdminEventTap(occurrence.eventId),
        ),
      ),
    );
  }
}

const double todaysEventsBodyHeight = 296;
