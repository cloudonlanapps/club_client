import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'duration_picker_dropdown.dart';

/// The Duration input of a schedule cluster: the hours and minutes picker
/// the session split uses ([DurationPickerDropdown]), in steps of
/// [stepMinutes] from [shortestMinutes] to [longestMinutes].
///
/// An existing event may be longer than [longestMinutes], or off the step.
/// It opens showing its real length: the picker's bounds stretch to the
/// length the field is given, and that length is kept until another is
/// picked. Every length picked is on the step and within the limits.
class ScheduleDurationField extends StatelessWidget {
  const ScheduleDurationField({
    required this.minutes,
    required this.longestMinutes,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// The step between the lengths offered: the picker's own.
  static const int stepMinutes = 15;

  /// The shortest length offered.
  static const int shortestMinutes = 15;

  /// Width of the picker: that of a session's length in the split below.
  static const double pickerWidth = 110;

  /// The length shown.
  final int minutes;

  /// The longest length offered.
  final int longestMinutes;

  /// Called with the length picked, in minutes.
  final ValueChanged<int> onChanged;

  /// Whether the picker opens.
  final bool enabled;

  /// [picked] as a length this field offers: down to the step, and within
  /// [shortestMinutes] and [longestMinutes].
  int offered(int picked) => (picked - picked % stepMinutes).clamp(
    shortestMinutes,
    longestMinutes,
  );

  void onPicked(Duration picked) {
    // Picking the length already shown changes nothing, so a length this
    // field does not offer is kept.
    if (picked.inMinutes == minutes) return;
    onChanged(offered(picked.inMinutes));
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: pickerWidth,
        child: DurationPickerDropdown(
          value: Duration(minutes: minutes),
          min: Duration(
            minutes: math.min(shortestMinutes, math.max(minutes, 0)),
          ),
          max: Duration(minutes: math.max(longestMinutes, minutes)),
          enabled: enabled,
          onChanged: onPicked,
        ),
      ),
    );
  }
}
