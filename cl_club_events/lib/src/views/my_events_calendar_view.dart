import 'package:cl_calendar/cl_calendar.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show clMyOccurrencesListProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorView, LoadingView, TitleRow;
import '../widgets/calendar_grid.dart';
import '../widgets/cards/occurrence_card.dart';

/// Calendar view for a member showing their enrolled occurrences.
class MyEventsCalendarView extends ConsumerWidget {
  const MyEventsCalendarView({
    required this.currentUser,
    required this.targetUsername,
    required this.viewingSelf,
    required this.onHome,
    this.displayName,
    this.onEventTap,
    this.onBack,
    super.key,
  });

  final UserPrivate currentUser;
  final String targetUsername;

  /// True when the logged-in user is browsing their own calendar (renders
  /// "My Calendar"); false when an admin / coach / guardian is viewing
  /// another user (renders `<name>'s Calendar`).
  final bool viewingSelf;
  final String? displayName;
  final ValueChanged<int>? onEventTap;
  final VoidCallback onHome;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final title = viewingSelf
        ? 'My Calendar'
        : "${displayName ?? targetUsername}'s Calendar";

    return GetCalendarViewRange(
      builder: (controller, range, selectedDateTime, onChangeSelectedDateTime) {
        // Key the month-bounds off the calendar's `range`, NOT the
        // (possibly-stale) `selectedDateTime`. Month navigation only
        // updates `range` — deriving bounds from `selectedDateTime`
        // froze the provider key and showed previous-month events
        // until the user tapped a day. See issue #682.
        final monthStart = range.start;
        final monthEnd = range.end;

        final occurrencesAsync = ref.watch(
          clMyOccurrencesListProvider((
            username: targetUsername,
            fromTimeUtc: monthStart,
            toTimeUtc: monthEnd,
          )),
        );

        return Column(
          children: [
            TitleRow(title: title, onBack: onBack),
            const Divider(height: 1),
            SizedBox(
              height: 320,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ShadCard(
                  backgroundColor: theme.colorScheme.background,
                  padding: const EdgeInsets.all(8),
                  child: CalendarGrid(memberUsername: targetUsername),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: occurrencesAsync.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(
                  title: 'Failed to load occurrences',
                  errorCode: '$error',
                  onHome: onHome,
                  onRetry: () => ref.invalidate(
                    clMyOccurrencesListProvider((
                      username: targetUsername,
                      fromTimeUtc: monthStart,
                      toTimeUtc: monthEnd,
                    )),
                  ),
                ),
                data: (occurrences) => buildDayOccurrences(
                  occurrences,
                  selectedDateTime,
                  (from: monthStart, to: monthEnd),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildDayOccurrences(
    List<Occurrence> allOccurrences,
    DateTime selectedDate,
    ({DateTime from, DateTime to}) range,
  ) {
    final dayOccurrences = allOccurrences.where((o) {
      final local = o.actualStartTimeUtc.toLocal();
      return DateUtils.isSameDay(local, selectedDate);
    }).toList();

    if (dayOccurrences.isEmpty) {
      return const Center(
        child: Text('No occurrences for this day'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: dayOccurrences.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => OccurrenceCard(
        eventId: dayOccurrences[index].eventId,
        occurrenceTime: dayOccurrences[index].originalStartTimeUtc,
        range: range,
        username: targetUsername,
        dense: true,
        muteTerminal: false,
        onTap: onEventTap == null
            ? null
            : () => onEventTap!(dayOccurrences[index].eventId),
      ),
    );
  }
}
