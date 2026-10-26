import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../event_schedule/time_picker_empty_parts.dart';

/// A time of day of an application, typed in the 24-hour picker: hours and
/// minutes, no seconds. The controller is seeded with no seconds, so the
/// picker gives a time once the hour and minute are typed (form rule 11).
class ApplicationTimeInput extends StatelessWidget {
  const ApplicationTimeInput({
    required this.controller,
    required this.enabled,
    super.key,
  });

  /// The picker's controller; its owner listens to it.
  final ShadTimePickerController controller;

  /// Whether the picker responds.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TimePickerEmptyParts(
        controller: controller,
        child: ShadTimePicker(
          controller: controller,
          enabled: enabled,
          showSeconds: false,
          hourLabel: const SizedBox.shrink(),
          minuteLabel: const SizedBox.shrink(),
          gap: 0,
        ),
      ),
    );
  }
}
