import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/detached_date_field.dart';
import 'marketing_date_text.dart';

/// A date cell of a marketing list row: the day, picked on the shared date
/// field ([CLDatePickerFormField]), and a button that empties it.
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
    final theme = ShadTheme.of(context);
    return Row(
      children: [
        Expanded(
          child: DetachedDateField(
            value: day,
            child: CLDatePickerFormField(
              initialValue: day,
              enabled: enabled,
              placeholder: Text(
                placeholder ?? '',
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
              formatDate: marketingDateText,
              onChanged: (date) {
                if (date != null) onChanged(date);
              },
            ),
          ),
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
