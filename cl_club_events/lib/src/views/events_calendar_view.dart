import 'package:cl_calendar/cl_calendar.dart';
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show TitleRow;

import '../models/selected_occurrence.dart';
import '../providers/cached_date_items.dart';
import '../widgets/calendar_grid.dart';
import '../widgets/cards/occurrence_card.dart';

/// Admin calendar view: month grid on top, list of selected day's
/// occurrences below. Mirrors the layout of `MyEventsCalendarView`.
///
/// `onMarkAttendance` is invoked when an admin taps the per-tile
/// "Attendance" button. The hosting screen wires it to navigation that
/// pushes the dedicated attendance route.
class EventsCalendarView extends ConsumerWidget {
  const EventsCalendarView({
    required this.currentUser,
    required this.onMarkAttendance,
    this.onBack,
    super.key,
  });

  final UserPrivate currentUser;
  final void Function(int eventId, DateTime occurrenceTimeUtc) onMarkAttendance;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);

    return GetCalendarViewRange(
      builder: (controller, range, selectedDateTime, onChangeSelectedDateTime) {
        final date = DateUtils.dateOnly(selectedDateTime);
        final cached = ref.watch(
          cachedDateItemsProvider((
            date: date,
            range: range,
          )),
        );

        final items = cached.data ?? [];

        return Column(
          children: [
            TitleRow(title: 'Club Calendar', onBack: onBack),
            const Divider(height: 1),
            SizedBox(
              height: 320,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ShadCard(
                  backgroundColor: theme.colorScheme.background,
                  padding: const EdgeInsets.all(8),
                  child: const CalendarGrid(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AdminDayOccurrencesList(
                items: items,
                range: (from: range.start, to: range.end),
                onMarkAttendance: onMarkAttendance,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// List of admin occurrence tiles for the selected day, or an empty-state
/// message when none.
class AdminDayOccurrencesList extends StatelessWidget {
  const AdminDayOccurrencesList({
    required this.items,
    required this.range,
    required this.onMarkAttendance,
    super.key,
  });

  final List<SelectedOccurrence> items;
  final ({DateTime from, DateTime to}) range;
  final void Function(int eventId, DateTime occurrenceTimeUtc) onMarkAttendance;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No occurrences for this day'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final (occurrence, _) = items[index];
        return OccurrenceCard(
          eventId: occurrence.eventId,
          occurrenceTime: occurrence.originalStartTimeUtc,
          range: range,
          dense: true,
          muteTerminal: false,
          onMarkAttendance: onMarkAttendance,
        );
      },
    );
  }
}
