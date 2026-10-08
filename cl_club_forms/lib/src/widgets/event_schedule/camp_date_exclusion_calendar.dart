import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Calendar widget for selecting dates to exclude from a camp.
///
/// Shows the camp duration highlighted and allows tapping dates to toggle
/// exclusion.
class CampDateExclusionCalendar extends StatefulWidget {
  const CampDateExclusionCalendar({
    required this.campStartDate,
    required this.durationDays,
    required this.excludedDates,
    required this.onChanged,
    super.key,
    this.enabled = true,
  });
  final DateTime campStartDate;
  final int durationDays;
  final Set<DateTime> excludedDates;
  final ValueChanged<Set<DateTime>> onChanged;
  final bool enabled;

  @override
  State<CampDateExclusionCalendar> createState() =>
      CampDateExclusionCalendarState();
}

class CampDateExclusionCalendarState extends State<CampDateExclusionCalendar> {
  late DateTime displayedMonth;

  @override
  void initState() {
    super.initState();
    displayedMonth = DateTime(
      widget.campStartDate.year,
      widget.campStartDate.month,
    );
  }

  @override
  void didUpdateWidget(CampDateExclusionCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-navigate to new start date when it changes
    if (widget.campStartDate != oldWidget.campStartDate) {
      setState(() {
        displayedMonth = DateTime(
          widget.campStartDate.year,
          widget.campStartDate.month,
        );
      });
    }
  }

  DateTime get campEndDate =>
      widget.campStartDate.add(Duration(days: widget.durationDays - 1));

  bool isInCampRange(DateTime date) {
    final dateOnly = DateUtils.dateOnly(date);
    final startOnly = DateUtils.dateOnly(widget.campStartDate);
    final endOnly = DateUtils.dateOnly(campEndDate);
    return !dateOnly.isBefore(startOnly) && !dateOnly.isAfter(endOnly);
  }

  bool isExcluded(DateTime date) {
    final dateOnly = DateUtils.dateOnly(date);
    return widget.excludedDates.any(
      (d) => DateUtils.dateOnly(d) == dateOnly,
    );
  }

  void toggleExclusion(DateTime date) {
    if (!widget.enabled || !isInCampRange(date)) return;

    final dateOnly = DateUtils.dateOnly(date);
    final newExcluded = Set<DateTime>.from(widget.excludedDates);

    if (isExcluded(date)) {
      newExcluded.removeWhere((d) => DateUtils.dateOnly(d) == dateOnly);
    } else {
      newExcluded.add(dateOnly);
    }

    widget.onChanged(newExcluded);
  }

  void previousMonth() {
    setState(() {
      displayedMonth = DateTime(
        displayedMonth.year,
        displayedMonth.month - 1,
      );
    });
  }

  void nextMonth() {
    setState(() {
      displayedMonth = DateTime(
        displayedMonth.year,
        displayedMonth.month + 1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Month navigation header
              buildHeader(theme),
              const Divider(height: 1),
              // Day labels
              buildDayLabels(theme),
              // Calendar grid
              buildCalendarGrid(theme),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Legend
        buildLegend(theme),
      ],
    );
  }

  Widget buildHeader(ShadThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: widget.enabled ? previousMonth : null,
          ),
          Text(
            DateFormat('MMMM yyyy').format(displayedMonth),
            style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: widget.enabled ? nextMonth : null,
          ),
        ],
      ),
    );
  }

  Widget buildDayLabels(ShadThemeData theme) {
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: dayLabels.map((label) {
          return Expanded(
            child: Center(
              child: Text(
                label,
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.mutedForeground,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildCalendarGrid(ShadThemeData theme) {
    final firstDayOfMonth = DateTime(displayedMonth.year, displayedMonth.month);
    final lastDayOfMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month + 1,
      0,
    );

    // Get Monday of the week containing the first day
    var startDay = firstDayOfMonth;
    while (startDay.weekday != DateTime.monday) {
      startDay = startDay.subtract(const Duration(days: 1));
    }

    final days = <DateTime>[];
    var current = startDay;
    while (current.isBefore(lastDayOfMonth) ||
        current.month == displayedMonth.month ||
        days.length % 7 != 0) {
      days.add(current);
      current = current.add(const Duration(days: 1));
      if (days.length >= 42) break; // Max 6 weeks
    }

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: List.generate((days.length / 7).ceil(), (weekIndex) {
          return Row(
            children: List.generate(7, (dayIndex) {
              final index = weekIndex * 7 + dayIndex;
              if (index >= days.length) {
                return const Expanded(child: SizedBox(height: 40));
              }
              final date = days[index];
              return Expanded(child: buildDayCell(date, theme));
            }),
          );
        }),
      ),
    );
  }

  Widget buildDayCell(DateTime date, ShadThemeData theme) {
    final isCurrentMonth = date.month == displayedMonth.month;
    final isInRange = isInCampRange(date);
    final excluded = isExcluded(date);
    final isToday = DateUtils.isSameDay(date, DateTime.now());

    Color? backgroundColor;
    var textColor = theme.colorScheme.foreground;
    var fontWeight = FontWeight.normal;

    if (!isCurrentMonth) {
      textColor = theme.colorScheme.mutedForeground.withValues(alpha: 0.3);
    } else if (isInRange) {
      if (excluded) {
        backgroundColor = theme.colorScheme.destructive.withValues(alpha: 0.2);
        textColor = theme.colorScheme.destructive;
      } else {
        backgroundColor = theme.colorScheme.primary.withValues(alpha: 0.2);
        textColor = theme.colorScheme.primary;
        fontWeight = FontWeight.w600;
      }
    }

    return GestureDetector(
      onTap: isInRange && widget.enabled ? () => toggleExclusion(date) : null,
      child: Container(
        height: 40,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: isToday
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${date.day}',
              style: theme.textTheme.small.copyWith(
                color: textColor,
                fontWeight: fontWeight,
                decoration: excluded ? TextDecoration.lineThrough : null,
              ),
            ),
            if (excluded)
              Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.close,
                  size: 10,
                  color: theme.colorScheme.destructive,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildLegend(ShadThemeData theme) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        buildLegendItem(
          theme,
          'Camp days',
          theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
        buildLegendItem(
          theme,
          'Excluded (rest days)',
          theme.colorScheme.destructive.withValues(alpha: 0.2),
        ),
      ],
    );
  }

  Widget buildLegendItem(ShadThemeData theme, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
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
