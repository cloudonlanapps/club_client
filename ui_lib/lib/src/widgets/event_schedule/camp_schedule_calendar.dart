import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Read-only, non-navigable calendar for a camp's schedule.
///
/// Renders a month-style grid (Mon–Sun columns) but bounded to just the weeks
/// the camp spans — never a whole month — so a short camp shows only its own
/// rows. Colours match the editor (`CampDateExclusionCalendar`): camp days are
/// shaded in the primary accent; rest days in the destructive shade with the
/// day struck through. Pure display: no taps, no month navigation.
class CampScheduleCalendar extends StatelessWidget {
  const CampScheduleCalendar({
    required this.startDate,
    required this.durationDays,
    this.excludedDates = const <DateTime>{},
    super.key,
  });

  /// Local date of the first camp day.
  final DateTime startDate;

  /// Total calendar span in days (training days + rest days); at least 1.
  final int durationDays;

  /// Local date-only rest days within the window.
  final Set<DateTime> excludedDates;

  static const _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const _monthNames = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  DateTime get _start => DateUtils.dateOnly(startDate);
  DateTime get _end => _start.add(Duration(days: durationDays - 1));

  bool _inCamp(DateTime d) => !d.isBefore(_start) && !d.isAfter(_end);

  bool _isRest(DateTime d) =>
      excludedDates.any((e) => DateUtils.dateOnly(e) == d);

  List<List<DateTime>> _weeks() {
    var cursor = _start;
    while (cursor.weekday != DateTime.monday) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    final weeks = <List<DateTime>>[];
    while (!cursor.isAfter(_end)) {
      weeks.add([for (var i = 0; i < 7; i++) cursor.add(Duration(days: i))]);
      cursor = cursor.add(const Duration(days: 7));
    }
    return weeks;
  }

  String _rangeLabel() {
    final s = _start;
    final e = _end;
    if (s.year == e.year && s.month == e.month) {
      return '${_monthNames[s.month]} ${s.year}';
    }
    if (s.year == e.year) {
      return '${_monthNames[s.month]} – ${_monthNames[e.month]} ${s.year}';
    }
    return '${_monthNames[s.month]} ${s.year} – '
        '${_monthNames[e.month]} ${e.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final muted = theme.colorScheme.mutedForeground;
    final hasRest = excludedDates.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 6),
            child: Text(
              _rangeLabel(),
              style: theme.textTheme.small.copyWith(
                color: muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Row(
            children: [
              for (final label in _weekdayLabels)
                Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: theme.textTheme.small.copyWith(
                        color: muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          for (final week in _weeks())
            Row(
              children: [
                for (final day in week)
                  Expanded(
                    child: _DayCell(
                      day: day,
                      inCamp: _inCamp(day),
                      isRest: _isRest(day),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendSwatch(
                label: 'Camp day',
                color: theme.colorScheme.primary,
              ),
              if (hasRest) ...[
                const SizedBox(width: 16),
                _LegendSwatch(
                  label: 'Rest day',
                  color: theme.colorScheme.destructive,
                  struck: true,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// One day cell: shaded for camp days, shaded + struck for rest days, faint for
/// the filler days that pad the first/last week.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.inCamp,
    required this.isRest,
  });

  final DateTime day;
  final bool inCamp;
  final bool isRest;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    Color? background;
    // Filler days padding the first/last week, matching the editor's
    // out-of-range tint.
    var textColor = theme.colorScheme.mutedForeground.withValues(alpha: 0.3);
    var weight = FontWeight.normal;
    TextDecoration? decoration;

    if (inCamp) {
      if (isRest) {
        // Rest day — destructive shade + strike-through, like the editor.
        background = theme.colorScheme.destructive.withValues(alpha: 0.2);
        textColor = theme.colorScheme.destructive;
        decoration = TextDecoration.lineThrough;
      } else {
        // Camp day — primary accent, like the editor.
        background = theme.colorScheme.primary.withValues(alpha: 0.2);
        textColor = theme.colorScheme.primary;
        weight = FontWeight.w600;
      }
    }

    return Container(
      height: 34,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: theme.textTheme.small.copyWith(
          color: textColor,
          fontWeight: weight,
          decoration: decoration,
        ),
      ),
    );
  }
}

/// A small colour swatch + label for the legend. [color] matches the day-cell
/// shade it stands for (primary for camp days, destructive for rest days).
class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({
    required this.label,
    required this.color,
    this.struck = false,
  });

  final String label;
  final Color color;
  final bool struck;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: struck
              ? Text(
                  '1',
                  style: theme.textTheme.small.copyWith(
                    fontSize: 9,
                    color: color,
                    decoration: TextDecoration.lineThrough,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.small.copyWith(
            color: theme.colorScheme.mutedForeground,
          ),
        ),
      ],
    );
  }
}
