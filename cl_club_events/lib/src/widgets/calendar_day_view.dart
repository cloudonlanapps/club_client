import 'package:cl_calendar/cl_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show FilmRollColorsExtension;

import '../providers/day_event_counts.dart';
import '../providers/my_day_event_counts.dart';

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
  /// (`/occurrences/`) is used.
  final String? memberUsername;

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

        Color? backgroundColor;
        if (isSelected) {
          backgroundColor = theme.colorScheme.selection;
        } else if (isToday) {
          backgroundColor = theme.colorScheme.muted;
        } else if (hasSpecialEvent) {
          backgroundColor = theme.colorScheme.specialEventHighlight;
        }

        return GestureDetector(
          onTap: () => onChangeSelectedDateTime(date),
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Container(
              decoration: BoxDecoration(color: backgroundColor),
              alignment: Alignment.center,
              child: Text(
                date.day.toString(),
                style: theme.textTheme.large.copyWith(
                  color: isSelected
                      ? theme.colorScheme.primaryForeground
                      : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
