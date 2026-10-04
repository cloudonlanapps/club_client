import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorView, LoadingView, TitleRow;

import '../utils/time_formatter.dart';
import '../widgets/attendance_day_group.dart';

/// Scaffold-free attendance dashboard view showing month-by-month
/// attendance records for a user.
///
/// Takes a [targetUsername] — the user whose attendance is shown, which
/// may differ from [currentUser] when an admin or coach is viewing.
/// Designed to be wrapped in a Scaffold by the host screen.
class MyEventsAttendanceView extends ConsumerStatefulWidget {
  const MyEventsAttendanceView({
    required this.currentUser,
    required this.targetUsername,
    required this.onHome,
    this.viewingSelf = true,
    this.displayName,
    this.onBack,
    super.key,
  });

  final UserPrivate currentUser;
  final String targetUsername;
  final bool viewingSelf;
  final String? displayName;
  final VoidCallback onHome;
  final VoidCallback? onBack;

  @override
  ConsumerState<MyEventsAttendanceView> createState() =>
      MyEventsAttendanceViewState();
}

class MyEventsAttendanceViewState
    extends ConsumerState<MyEventsAttendanceView> {
  DateTime currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void navigateToPreviousMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
    });
  }

  void navigateToNextMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    final fromTimeUtc = DateTime.utc(currentMonth.year, currentMonth.month);
    final toTimeUtc = DateTime.utc(currentMonth.year, currentMonth.month + 1);

    final attendanceAsync = ref.watch(
      clMyAttendanceListProvider((
        username: widget.targetUsername,
        fromTimeUtc: fromTimeUtc,
        toTimeUtc: toTimeUtc,
      )),
    );

    final eventsAsync = ref.watch(
      clMyEventsMasterProvider(widget.targetUsername),
    );

    final title = widget.viewingSelf
        ? 'My Attendance'
        : 'Attendance of ${widget.displayName ?? widget.targetUsername}';
    return Column(
      children: [
        TitleRow(title: title, onBack: widget.onBack),
        // Month navigation header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.border),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: navigateToPreviousMonth,
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(currentMonth),
                  style: theme.textTheme.h4,
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: navigateToNextMonth,
              ),
            ],
          ),
        ),
        // Scrollable attendance list
        Expanded(
          child: attendanceAsync.when(
            loading: () => const LoadingView(),
            error: (error, _) => ErrorView(
              title: 'Failed to load attendance',
              errorCode: '$error',
              onHome: widget.onHome,
              onRetry: () => ref.invalidate(
                clMyAttendanceListProvider((
                  username: widget.targetUsername,
                  fromTimeUtc: fromTimeUtc,
                  toTimeUtc: toTimeUtc,
                )),
              ),
            ),
            data: (records) => buildAttendanceList(
              records,
              eventsAsync.valueOrNull,
            ),
          ),
        ),
        // Legend pinned at bottom
        buildLegend(theme),
      ],
    );
  }

  Widget buildAttendanceList(
    List<MyAttendanceRecord> records,
    List<Event>? events,
  ) {
    if (records.isEmpty) {
      return const Center(
        child: Text('No attendance records for this month'),
      );
    }

    // Group records by day (local date)
    final grouped = <DateTime, List<MyAttendanceRecord>>{};
    for (final record in records) {
      final localDate = record.occurrenceTimeUtc.toLocal();
      final dayKey = DateTime(localDate.year, localDate.month, localDate.day);
      grouped.putIfAbsent(dayKey, () => []).add(record);
    }

    final sortedDays = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDays.length,
      itemBuilder: (context, index) {
        final day = sortedDays[index];
        final dayRecords = grouped[day]!;

        final entries = dayRecords.map((record) {
          final event = events
              ?.where((e) => e.id == record.eventId)
              .firstOrNull;
          return OccurrenceEntry(
            eventTitle: event?.title ?? 'Event #${record.eventId}',
            eventType: event?.type ?? EventType.oneOff,
            attendanceStatus: record.status,
            timeRange: event != null
                ? formatTimeRange(event.startTimeUtc, event.endTimeUtc)
                : null,
          );
        }).toList();

        return AttendanceDayGroup(date: day, entries: entries);
      },
    );
  }

  Widget buildLegend(ShadThemeData theme) {
    final labelStyle = theme.textTheme.small.copyWith(
      color: theme.colorScheme.mutedForeground,
      fontSize: 11,
    );
    final codeStyle = labelStyle.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w700,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: theme.colorScheme.border),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: [
          legendItem('P', 'Present', codeStyle, labelStyle),
          legendItem('A', 'Absent', codeStyle, labelStyle),
          legendItem('L', 'Late', codeStyle, labelStyle),
          legendItem('OL', 'On Leave', codeStyle, labelStyle),
          legendItem('LR', 'Leave Requested', codeStyle, labelStyle),
        ],
      ),
    );
  }

  Widget legendItem(
    String code,
    String label,
    TextStyle codeStyle,
    TextStyle labelStyle,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            border: Border.all(
              color: labelStyle.color!,
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(code, style: codeStyle),
        ),
        const SizedBox(width: 4),
        Text(label, style: labelStyle),
      ],
    );
  }
}
