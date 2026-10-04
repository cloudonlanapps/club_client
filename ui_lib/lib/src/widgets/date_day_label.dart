import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Displays a bold day number with an abbreviated day name below.
///
/// SDK-free, reusable widget suitable for calendar-style date labels.
class DateDayLabel extends StatelessWidget {
  const DateDayLabel({required this.date, super.key});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final dayNumber = date.day.toString();
    final dayName = _abbreviatedDayName(date.weekday);

    return SizedBox(
      width: 36,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dayNumber,
            style: theme.textTheme.p.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          Text(
            dayName,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  String _abbreviatedDayName(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'Mon',
      DateTime.tuesday => 'Tue',
      DateTime.wednesday => 'Wed',
      DateTime.thursday => 'Thu',
      DateTime.friday => 'Fri',
      DateTime.saturday => 'Sat',
      DateTime.sunday => 'Sun',
      _ => '',
    };
  }
}
