import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../form/detached_date_field.dart';
import '../application_form_strings.dart';
import '../items/application_item_frame.dart';
import 'application_day_text.dart';

/// A day of an application, picked on the shared date field
/// ([CLDatePickerFormField]), and, when [onCleared] is given and a day is
/// set, a button that clears it.
class ApplicationDateInput extends StatelessWidget {
  const ApplicationDateInput({
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.onCleared,
    super.key,
  });

  /// The width of the date field: room for the longest day, as the schedule
  /// forms size theirs.
  static const double width = 180;

  /// The day as the template stores it; `''` for none.
  final String value;

  /// Whether the inputs respond.
  final bool enabled;

  /// Called with the day picked, as the template stores it.
  final ValueChanged<String> onChanged;

  /// Clears the day; null when it may not be cleared.
  final VoidCallback? onCleared;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Row(
      children: [
        SizedBox(
          width: width,
          child: DetachedDateField(
            value: value,
            child: CLDatePickerFormField(
              initialValue: DateTime.tryParse(value),
              enabled: enabled,
              placeholder: Text(
                ApplicationFormStrings.pickDateHint,
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
              formatDate: (date) =>
                  ApplicationDayText.of(ApplicationDayText.stored(date)),
              onChanged: (date) {
                if (date != null) onChanged(ApplicationDayText.stored(date));
              },
            ),
          ),
        ),
        if (onCleared != null && value.isNotEmpty)
          ShadIconButton.ghost(
            enabled: enabled,
            icon: const Icon(
              LucideIcons.x,
              size: ApplicationItemFrame.iconSize,
            ),
            onPressed: onCleared,
          ),
      ],
    );
  }
}
