import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Weekday name abbreviations (Mon-Sun).
const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Weekday full names (Monday-Sunday).
const weekdayFullNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Single-letter labels rendered on each chip (M T W T F S S).
const weekdayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// Horizontal row of square chips for picking weekdays (1-7, 1=Monday).
///
/// Selected chips are filled with the primary colour; unselected chips use
/// the muted background. Tap a chip to toggle the day on/off.
class WeekdaySelector extends StatelessWidget {
  const WeekdaySelector({
    required this.selectedDays,
    required this.onChanged,
    super.key,
    this.enabled = true,
  });

  final Set<int> selectedDays;
  final ValueChanged<Set<int>> onChanged;
  final bool enabled;

  void toggle(int dayNum) {
    final next = Set<int>.from(selectedDays);
    if (next.contains(dayNum)) {
      next.remove(dayNum);
    } else {
      next.add(dayNum);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          WeekdayChip(
            letter: weekdayInitials[i],
            tooltip: weekdayFullNames[i],
            selected: selectedDays.contains(i + 1),
            enabled: enabled,
            onTap: () => toggle(i + 1),
          ),
        ],
      ],
    );
  }
}

class WeekdayChip extends StatelessWidget {
  const WeekdayChip({
    required this.letter,
    required this.tooltip,
    required this.selected,
    required this.onTap,
    this.enabled = true,
    super.key,
  });

  final String letter;
  final String tooltip;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final background = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.muted;
    final foreground = selected
        ? theme.colorScheme.primaryForeground
        : theme.colorScheme.foreground;

    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onTap : null,
          child: MouseRegion(
            cursor: enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                letter,
                style: theme.textTheme.small.copyWith(
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
