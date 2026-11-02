import 'package:cl_calendar/cl_calendar.dart';
import 'package:club_sdk_2/club_sdk_2.dart' show Occurrence;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show FilmRollColorsExtension;

import '../models/attendance_progress.dart';
import '../providers/cached_occurrences.dart';
import '../providers/day_event_counts.dart';
import '../providers/my_day_attendance.dart';
import '../providers/my_day_event_counts.dart';
import 'attendance_pie.dart';
import 'attendance_progress_icon.dart';

/// A day of the calendar's month view: its date, the selected / today /
/// camp-or-one-off highlight and, on the staff calendar, how far the day's
/// attendance is taken in the bottom-right corner (club_client#414).
class CalendarDayView extends ConsumerWidget {
  const CalendarDayView({
    required this.date,
    required this.size,
    required this.range,
    required this.selectedDateTime,
    required this.onChangeSelectedDateTime,
    this.memberUsername,
    super.key,
  });

  final DateTime date;
  final Size size;
  final CalendarViewRange range;
  final DateTime selectedDateTime;
  final void Function(DateTime) onChangeSelectedDateTime;

  /// When non-null, day counts come from the member endpoint
  /// (`/myevents/{username}/...`). When null, the admin endpoint
  /// (`/occurrences/`) is used. A member's day also shows a pie of its
  /// recorded attendance (club_client#416).
  final String? memberUsername;

  /// The size of the corner mark (the staff calendar's attendance mark,
  /// the member's attendance pie), as a share of the cell's height.
  static const double markShare = 0.25;

  /// The corner mark's gap from the cell's bottom-right corner, as a
  /// share of the cell's height.
  static const double markInset = 0.06;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GetReferenceDateTimeUtc(
      builder: (refDate) {
        final effectiveRefDate = refDate ?? DateTime.now().toUtc();
        final isToday = DateUtils.isSameDay(date, effectiveRefDate.toLocal());
        final isSelected = DateUtils.isSameDay(date, selectedDateTime);
        final theme = ShadTheme.of(context);

        final eventCountsAsync = memberUsername != null
            ? ref.watch(
                myDayEventCountsProvider((
                  username: memberUsername!,
                  range: range,
                )),
              )
            : ref.watch(
                dayEventCountsProvider((
                  range: range,
                )),
              );
        final hasSpecialEvent = eventCountsAsync.maybeWhen(
          data: (counts) {
            final dateOnly = DateUtils.dateOnly(date);
            final dayCounts = counts[dateOnly];
            return dayCounts != null &&
                (dayCounts.oneoff > 0 || dayCounts.camp > 0);
          },
          orElse: () => false,
        );

        // The staff calendar marks how far the day's attendance is taken,
        // from the occurrence list the cells already read (club_client#414);
        // the member's calendar does not.
        final attendance = memberUsername != null
            ? AttendanceProgress.none
            : AttendanceProgress.ofDay([
                for (final o
                    in ref
                            .watch(cachedOccurrencesProvider((range: range)))
                            .data ??
                        const <Occurrence>[])
                  if (DateUtils.isSameDay(o.actualStartTimeUtc.toLocal(), date))
                    o,
              ]);

        Color? backgroundColor;
        if (isSelected) {
          backgroundColor = theme.colorScheme.selection;
        } else if (isToday) {
          backgroundColor = theme.colorScheme.muted;
        } else if (hasSpecialEvent) {
          backgroundColor = theme.colorScheme.specialEventHighlight;
        }

        final dayAttendance = memberUsername == null
            ? null
            : ref
                  .watch(
                    myDayAttendanceProvider((
                      username: memberUsername!,
                      range: range,
                    )),
                  )
                  .valueOrNull?[DateUtils.dateOnly(date)];

        return GestureDetector(
          onTap: () => onChangeSelectedDateTime(date),
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Container(
              decoration: BoxDecoration(color: backgroundColor),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: Text(
                      date.day.toString(),
                      style: theme.textTheme.large.copyWith(
                        color: isSelected
                            ? theme.colorScheme.primaryForeground
                            : null,
                      ),
                    ),
                  ),
                  if (attendance != AttendanceProgress.none)
                    Positioned(
                      right: size.height * markInset,
                      bottom: size.height * markInset,
                      child: AttendanceProgressIcon(
                        progress: attendance,
                        size: size.height * markShare,
                        color: isSelected
                            ? theme.colorScheme.primaryForeground
                            : null,
                      ),
                    ),
                  if (dayAttendance != null && dayAttendance.isNotEmpty)
                    Positioned(
                      right: size.height * markInset,
                      bottom: size.height * markInset,
                      child: AttendancePie(
                        statuses: dayAttendance,
                        diameter: size.height * markShare,
                        outlineColor:
                            backgroundColor ?? theme.colorScheme.background,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
