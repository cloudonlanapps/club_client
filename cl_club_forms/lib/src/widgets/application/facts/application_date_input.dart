import 'package:cl_calendar/cl_calendar.dart' show CLDatePicker;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../application_form_strings.dart';
import '../items/application_item_frame.dart';
import 'application_day_text.dart';

/// A day of an application, picked on the shared calendar picker: a button
/// showing the day, which opens the picker, and, when [onCleared] is
/// given and a day is set, a button that clears it.
class ApplicationDateInput extends StatelessWidget {
  const ApplicationDateInput({
    required this.value,
    required this.enabled,
    required this.onChanged,
    this.onCleared,
    super.key,
  });

  /// The day as the template stores it; `''` for none.
  final String value;

  /// Whether the buttons respond.
  final bool enabled;

  /// Called with the day picked, as the template stores it.
  final ValueChanged<String> onChanged;

  /// Clears the day; null when it may not be cleared.
  final VoidCallback? onCleared;

  @override
  Widget build(BuildContext context) {
    const size = ApplicationItemFrame.iconSize;
    final button = ShadButton.outline(
      enabled: enabled,
      leading: const Icon(LucideIcons.calendar, size: size),
      child: Text(
        value.isEmpty
            ? ApplicationFormStrings.pickDateHint
            : ApplicationDayText.of(value),
      ),
    );
    return Row(
      children: [
        if (enabled)
          CLDatePicker(
            initialDate: DateTime.tryParse(value),
            onDateSelected: (date) =>
                onChanged(ApplicationDayText.stored(date)),
            child: button,
          )
        else
          button,
        if (onCleared != null && value.isNotEmpty)
          ShadIconButton.ghost(
            enabled: enabled,
            icon: const Icon(LucideIcons.x, size: size),
            onPressed: onCleared,
          ),
      ],
    );
  }
}
