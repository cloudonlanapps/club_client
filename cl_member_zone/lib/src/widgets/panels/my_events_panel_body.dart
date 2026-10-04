import 'package:cl_club_events/cl_club_events.dart';
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/selected_day.dart';
import '../../providers/today_my_occurrences.dart';
import 'dashboard_event_nav.dart';
import 'shared/day_occurrences_list.dart';

/// Body of the My Events dashboard panel.
///
/// Panel passes IDs + day range only; the card resolves the occurrence,
/// event, enrollment, and caption itself.
class MyEventsPanelBody extends ConsumerWidget {
  const MyEventsPanelBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const SizedBox(
        height: myEventsBodyHeight,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (!MembershipShim.isMember(user.roles)) {
      final myEvents = ref
          .watch(clMyEventsMasterProvider(user.username))
          .valueOrNull;
      if (myEvents == null || myEvents.isEmpty) {
        return const SizedBox.shrink();
      }
    }

    final selected = ref.watch(selectedDayProvider);
    final range = (
      from: startOfDayLocal(selected).toUtc(),
      to: endOfDayLocal(selected).toUtc(),
    );

    final nav = DashboardEventNav.of(context);
    return SizedBox(
      height: myEventsBodyHeight,
      child: DayOccurrencesList(
        source: todayMyOccurrencesProvider(user.username),
        emptyText: 'No events',
        errorPrefix: 'Could not load events',
        rowBuilder: (occurrence) => OccurrenceCard(
          eventId: occurrence.eventId,
          occurrenceTime: occurrence.originalStartTimeUtc,
          range: range,
          username: user.username,
          onTap: () => nav.onMyEventTap(user.username, occurrence.eventId),
        ),
      ),
    );
  }
}

const double myEventsBodyHeight = 296;
