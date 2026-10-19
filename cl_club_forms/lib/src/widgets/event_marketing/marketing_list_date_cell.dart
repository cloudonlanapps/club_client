import 'package:cl_calendar/cl_calendar.dart' show CLDatePicker;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'marketing_date_text.dart';

/// A date cell of a marketing list row: the day, picked from a calendar,
/// and a button that empties it.
class MarketingListDateCell extends StatelessWidget {
  const MarketingListDateCell({
    required this.value,
    required this.onChanged,
    required this.enabled,
    this.placeholder,
    super.key,
  });

  /// The day, or null when none is set.
  final DateTime? value;

  /// Called with the day picked, or null when it is emptied.
  final ValueChanged<DateTime?> onChanged;

  /// Whether the cell takes input.
  final bool enabled;

  /// What the cell says while it is empty.
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    final day = value;
    final button = ShadButton.outline(
      enabled: enabled,
      leading: const Icon(LucideIcons.calendar, size: 16),
      child: Text(day == null ? placeholder ?? '' : marketingDateText(day)),
    );
    return Row(
      children: [
        Expanded(
          child: enabled
              ? CLDatePicker(
                  initialDate: day,
                  onDateSelected: onChanged,
                  child: button,
                )
              : button,
        ),
        if (day != null)
          ShadIconButton.ghost(
            enabled: enabled,
            icon: const Icon(LucideIcons.x, size: 16),
            onPressed: () => onChanged(null),
          ),
      ],
    );
  }
}
