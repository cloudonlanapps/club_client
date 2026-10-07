import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/form_spacing.dart';
import '../../models/one_off_schedule_data.dart';
import '../form/labeled_form_row.dart';
import 'two_column_grid.dart';

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
  late TextEditingController durationController;
  late ShadTimePickerController startTimeController;

  @override
  void initState() {
    super.initState();
    final initial = widget.state.value ?? const OneOffScheduleData();
    selectedDate = initial.date;
    selectedStartTime = initial.startTime;
    durationMinutes = initial.durationMinutes;
    durationController = TextEditingController(
      text: formatDuration(durationMinutes),
    );
    startTimeController = ShadTimePickerController(
      hour: initial.startTime?.hour,
      // Pre-seed minute and second so the picker fires onChanged once the
      // user enters Hours. See CLAUDE.md form rule 11.
      minute: initial.startTime?.minute ?? 0,
      second: 0,
    );
  }

  @override
  void dispose() {
    durationController.dispose();
    startTimeController.dispose();
    super.dispose();
  }

  String formatDuration(int minutes) {
    final hours = minutes / 60;
    if (hours == hours.truncateToDouble()) return '${hours.toInt()}h';
    if (hours < 1) return '${minutes}m';
    final whole = hours.truncate();
    final fraction = minutes - whole * 60;
    if (fraction == 30) return '${whole}h 30m';
    return '${whole}h ${fraction}m';
  }

  int? parseDuration(String rawText) {
    final text = rawText.trim().toLowerCase();
    if (text.isEmpty) return null;
    final compound = RegExp(r'^(\d+)h\s*(\d+)?m?$').firstMatch(text);
    if (compound != null) {
      final hours = int.tryParse(compound.group(1)!) ?? 0;
      final mins = int.tryParse(compound.group(2) ?? '0') ?? 0;
      return hours * 60 + mins;
    }
    final decimalHours = RegExp(r'^(\d+(?:\.\d+)?)h?$').firstMatch(text);
    if (decimalHours != null) {
      final hours = double.tryParse(decimalHours.group(1)!) ?? 0;
      return (hours * 60).round();
    }
    final mOnly = RegExp(r'^(\d+)m$').firstMatch(text);
    if (mOnly != null) return int.tryParse(mOnly.group(1)!);
    return null;
  }

  String? validateDuration(String value) {
    final parsed = parseDuration(value);
    if (parsed == null || parsed <= 0) {
      return 'Duration must be greater than 0';
    }
    return null;
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

  void onDurationTextChanged(String value) {
    final parsed = parseDuration(value);
    if (parsed != null && parsed > 0) {
      setState(() => durationMinutes = parsed);
      emit();
    }
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
              field: ShadTimePickerFormField(
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
            LabeledFormRow(
              label: 'Duration',
              required: true,
              field: ShadInputFormField(
                controller: durationController,
                enabled: enabled,
                keyboardType: TextInputType.text,
                autocorrect: false,
                enableSuggestions: false,
                placeholder: const Text('e.g., 2h, 1.5h, 90m'),
                validator: validateDuration,
                onChanged: onDurationTextChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
