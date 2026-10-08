import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/form_spacing.dart';
import '../../models/one_off_schedule_data.dart';
import '../form/labeled_form_row.dart';
import 'schedule_duration_field.dart';
import 'time_picker_empty_parts.dart';
import 'two_column_grid.dart';

/// The longest one-off the Duration picker offers.
const int maxOneOffDurationMinutes = 8 * 60;

/// `ShadForm`-compatible field for one-off event schedule.
///
/// Wraps the date / start-time / duration trio into a single form value
/// of type [OneOffScheduleData]. Drop into any [ShadForm]:
///
/// ```dart
/// OneOffScheduleFormField(id: 'schedule', initialValue: data)
/// ```
///
/// The host reads the value back via `formKey.currentState!.value['schedule']`.
class OneOffScheduleFormField extends ShadFormBuilderField<OneOffScheduleData> {
  OneOffScheduleFormField({
    super.key,
    super.id,
    super.label,
    super.description,
    super.error,
    super.enabled,
    super.initialValue,
    super.validator,
    super.onChanged,
    super.onReset,
    super.onSaved,
    super.autovalidateMode,
    super.forceErrorText,
  }) : super(
         builder: (state) => OneOffScheduleFormFieldBody(state: state),
       );

  /// Aggregate validator. Reuses the same error strings the inline
  /// fields show, so callers can rely on either path.
  static String? aggregateValidator(OneOffScheduleData? value) {
    if (value == null) return 'Schedule is required';
    if (value.date == null) return 'Date is required';
    if (value.startTime == null) return 'Start time is required';
    if (value.durationMinutes <= 0) return 'Duration must be greater than 0';
    return null;
  }
}

/// Body for [OneOffScheduleFormField]. Public per project guideline
/// (no underscore-prefixed classes); not intended for direct
/// instantiation.
class OneOffScheduleFormFieldBody extends StatefulWidget {
  const OneOffScheduleFormFieldBody({required this.state, super.key});

  final FormFieldState<OneOffScheduleData> state;

  @override
  State<OneOffScheduleFormFieldBody> createState() =>
      OneOffScheduleFormFieldBodyState();
}

class OneOffScheduleFormFieldBodyState
    extends State<OneOffScheduleFormFieldBody> {
  late DateTime? selectedDate;
  late ShadTimeOfDay? selectedStartTime;
  late int durationMinutes;
  late ShadTimePickerController startTimeController;
  final GlobalKey<FormFieldState<ShadTimeOfDay>> _startTimeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final initial = widget.state.value ?? const OneOffScheduleData();
    selectedDate = initial.date;
    selectedStartTime = initial.startTime;
    durationMinutes = initial.durationMinutes;
    startTimeController = ShadTimePickerController(
      hour: initial.startTime?.hour,
      // Pre-seed minute and second so the picker fires onChanged once the
      // user enters Hours. See CLAUDE.md form rule 11.
      minute: initial.startTime?.minute ?? 0,
      second: 0,
    )..addListener(onStartTimeControllerChanged);
  }

  @override
  void dispose() {
    startTimeController.dispose();
    super.dispose();
  }

  /// The picker reports a time only once every part of it is filled. With
  /// a part emptied the start time is empty too, so the required rule
  /// refuses it.
  void onStartTimeControllerChanged() {
    if (startTimeController.value != null) return;
    if (selectedStartTime == null) return;
    _startTimeKey.currentState?.didChange(null);
  }

  void emit() {
    widget.state.didChange(
      OneOffScheduleData(
        date: selectedDate,
        startTime: selectedStartTime,
        durationMinutes: durationMinutes,
      ),
    );
  }

  void onDurationChanged(int minutes) {
    setState(() => durationMinutes = minutes);
    emit();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.state.widget.enabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: FormSpacing.rowGap,
      children: [
        TwoColumnGrid(
          runSpacing: FormSpacing.rowGap,
          children: [
            LabeledFormRow(
              label: 'Date',
              required: true,
              field: CLDatePickerFormField(
                initialValue: selectedDate,
                enabled: enabled,
                validator: (date) => date == null ? 'Date is required' : null,
                onChanged: (date) {
                  setState(() => selectedDate = date);
                  emit();
                },
              ),
            ),
            const SizedBox.shrink(),
          ],
        ),
        TwoColumnGrid(
          runSpacing: FormSpacing.rowGap,
          children: [
            LabeledFormRow(
              label: 'Start Time',
              required: true,
              field: TimePickerEmptyParts(
                controller: startTimeController,
                child: ShadTimePickerFormField(
                  key: _startTimeKey,
                  controller: startTimeController,
                  initialValue: selectedStartTime,
                  enabled: enabled,
                  showSeconds: false,
                  hourLabel: const SizedBox.shrink(),
                  minuteLabel: const SizedBox.shrink(),
                  // Match the plain inputs beside it: 14px digits (the picker
                  // defaults to 16) and no label gap (labels are hidden).
                  gap: 0,
                  style: ShadTheme.of(context).textTheme.muted,
                  validator: (time) =>
                      time == null ? 'Start time is required' : null,
                  onChanged: (time) {
                    setState(() => selectedStartTime = time);
                    emit();
                  },
                ),
              ),
            ),
            LabeledFormRow(
              label: 'Duration',
              required: true,
              field: ScheduleDurationField(
                minutes: durationMinutes,
                longestMinutes: maxOneOffDurationMinutes,
                enabled: enabled,
                onChanged: onDurationChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
