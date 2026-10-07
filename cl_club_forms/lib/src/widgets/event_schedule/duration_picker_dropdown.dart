import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'duration_picker_column.dart';

/// Two-column popover for picking a duration in hour:minute steps.
///
/// The trigger renders the currently-selected duration as `H:MM` and a
/// chevron. Tapping it opens a popover with a scrollable hours column
/// and a scrollable minutes column. Both columns are bounded by the
/// minimum and maximum durations the host supplies.
///
/// Shape and colour follow the rest of the schedule-form fields — bordered
/// row similar to `cl_calendar/lib/widgets/cl_date_picker_form_field.dart`,
/// no `InkWell` so it can be hosted inside a `ShadDialog` overlay without
/// needing a `Material` ancestor.
class DurationPickerDropdown extends StatefulWidget {
  const DurationPickerDropdown({
    required this.value,
    required this.onChanged,
    this.min = const Duration(minutes: 15),
    this.max = const Duration(hours: 8),
    this.step = const Duration(minutes: 15),
    this.enabled = true,
    this.placeholder,
    super.key,
  });

  /// Current selected duration. Will be clamped between [min] and [max] for
  /// display purposes only.
  final Duration value;

  /// Called when the user picks a new duration. The value is guaranteed to
  /// satisfy `min <= value <= max` and to be a multiple of [step] minutes.
  final ValueChanged<Duration> onChanged;

  /// Smallest allowed duration. Defaults to 15 minutes.
  final Duration min;

  /// Largest allowed duration.
  final Duration max;

  /// Granularity for the minutes column. Defaults to 15-minute steps.
  final Duration step;

  /// When `false`, the trigger is non-interactive and rendered with reduced
  /// opacity.
  final bool enabled;

  /// Optional placeholder when the value is at zero.
  final Widget? placeholder;

  @override
  State<DurationPickerDropdown> createState() => DurationPickerDropdownState();
}

class DurationPickerDropdownState extends State<DurationPickerDropdown> {
  final popoverController = ShadPopoverController();

  @override
  void dispose() {
    popoverController.dispose();
    super.dispose();
  }

  String formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes - hours * 60;
    return '$hours:${minutes.toString().padLeft(2, '0')}';
  }

  void selectHour(int hour) {
    final currentMinutes = widget.value.inMinutes - widget.value.inHours * 60;
    var picked = Duration(hours: hour, minutes: currentMinutes);
    picked = clampDuration(picked);
    widget.onChanged(picked);
  }

  void selectMinute(int minute) {
    final hours = widget.value.inHours;
    var picked = Duration(hours: hours, minutes: minute);
    picked = clampDuration(picked);
    widget.onChanged(picked);
  }

  Duration clampDuration(Duration d) {
    if (d < widget.min) return widget.min;
    if (d > widget.max) return widget.max;
    return d;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final clamped = clampDuration(widget.value);
    final maxHours = widget.max.inHours;
    final maxMinutes = widget.max.inMinutes;
    final minMinutes = widget.min.inMinutes;
    final stepMinutes = widget.step.inMinutes;

    final selectedHour = clamped.inHours;
    final selectedMinute = clamped.inMinutes - selectedHour * 60;

    // Drop minute options that would exceed the max (e.g. with max=0:30
    // hour=0, only [00, 15, 30] should appear) or fall below the min
    // (e.g. with min=0:15 hour=0, drop 00).
    final minuteOptions = <int>[
      for (var m = 0; m < 60; m += stepMinutes)
        if (selectedHour * 60 + m <= maxMinutes &&
            selectedHour * 60 + m >= minMinutes)
          m,
    ];

    final trigger = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled ? popoverController.toggle : null,
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: Opacity(
          opacity: widget.enabled ? 1 : 0.5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.border),
              borderRadius: BorderRadius.circular(6),
              color: theme.colorScheme.background,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    clamped == Duration.zero && widget.placeholder != null
                        ? ''
                        : formatDuration(clamped),
                    style: theme.textTheme.small.copyWith(
                      color: theme.colorScheme.foreground,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  LucideIcons.chevronDown,
                  size: 16,
                  color: theme.colorScheme.mutedForeground,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return ShadPopover(
      controller: popoverController,
      popover: (_) => SizedBox(
        width: 220,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: DurationPickerColumn(
                  label: 'Hours',
                  options: [for (var h = 0; h <= maxHours; h++) h],
                  selected: selectedHour,
                  formatter: (h) => h.toString(),
                  onSelected: (h) {
                    selectHour(h);
                    if (selectedMinute > 0 || h > 0) popoverController.hide();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DurationPickerColumn(
                  label: 'Minutes',
                  options: minuteOptions,
                  selected: selectedMinute,
                  formatter: (m) => m.toString().padLeft(2, '0'),
                  onSelected: (m) {
                    selectMinute(m);
                    popoverController.hide();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      child: trigger,
    );
  }
}
