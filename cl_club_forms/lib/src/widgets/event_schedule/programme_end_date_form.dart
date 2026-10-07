import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/programme_end_date_value.dart';
import '../form/labeled_form_row.dart';
import 'programme_end_date_form_validators.dart';

/// Pure-UI editor of a programme's end date: the last day it runs on, any
/// day from today, and the reason.
///
/// Under the day the form states what the choice gives, as the host words
/// it in [resultOf] (e.g. `Last session: Sat 14 Nov 2026.`), before
/// anything is saved.
///
/// SDK-free: the host drives the form through a
/// `GlobalKey<ProgrammeEndDateFormState>` —
/// [ProgrammeEndDateFormState.validate] from Save,
/// [ProgrammeEndDateFormState.isDirty] for no-op detection,
/// [ProgrammeEndDateFormState.reason] for an action that needs only the
/// reason — and shows a refusal with
/// [ProgrammeEndDateFormState.showFormError].
class ProgrammeEndDateForm extends StatefulWidget {
  const ProgrammeEndDateForm({
    required this.reasonRequired,
    required this.resultOf,
    this.initialDay,
    this.enabled = true,
    super.key,
  });

  /// Field id of the last day.
  static const String lastDayId = 'lastDay';

  /// Field id of the reason.
  static const String reasonId = 'reason';

  /// The day the programme ends on now; `null` when it has no end.
  final DateTime? initialDay;

  /// Whether a reason must be given (setting an end where there is none).
  final bool reasonRequired;

  /// What ending on the given day gives, in the host's words.
  final String Function(DateTime day) resultOf;

  /// Whether the fields accept input.
  final bool enabled;

  @override
  State<ProgrammeEndDateForm> createState() => ProgrammeEndDateFormState();
}

class ProgrammeEndDateFormState extends State<ProgrammeEndDateForm> {
  final formKey = GlobalKey<ShadFormState>();

  /// The form-level message of a refused save, shown inline.
  String? formError;

  /// The day chosen now.
  late DateTime? lastDay = widget.initialDay;

  /// The reason typed so far, trimmed.
  String get reason =>
      (formKey.currentState?.value[ProgrammeEndDateForm.reasonId] as String? ??
              '')
          .trim();

  /// Validates the day and the reason and returns them, else `null` (the
  /// fields say why).
  ProgrammeEndDateValue? validate() {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return null;
    final day = form.value[ProgrammeEndDateForm.lastDayId] as DateTime?;
    if (day == null) return null;
    setState(() => formError = null);
    return ProgrammeEndDateValue(lastDay: day, reason: reason);
  }

  /// Whether the chosen day differs from the one the programme ends on now.
  bool get isDirty {
    final day =
        formKey.currentState?.value[ProgrammeEndDateForm.lastDayId]
            as DateTime?;
    final initial = widget.initialDay;
    if (day == null || initial == null) return day != initial;
    return !DateUtils.isSameDay(day, initial);
  }

  /// Shows [message] as the inline form-level message.
  void showFormError(String message) => setState(() => formError = message);

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final muted = theme.textTheme.small.copyWith(
      color: theme.colorScheme.mutedForeground,
    );
    final day = lastDay;
    final error = formError;
    return ShadForm(
      key: formKey,
      initialValue: {
        ProgrammeEndDateForm.lastDayId: widget.initialDay,
        ProgrammeEndDateForm.reasonId: '',
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          LabeledFormRow(
            label: 'Last day',
            required: true,
            field: CLDatePickerFormField(
              id: ProgrammeEndDateForm.lastDayId,
              initialValue: widget.initialDay,
              enabled: widget.enabled,
              yearsBefore: 0,
              validator: ProgrammeEndDateFormValidators.lastDay,
              onChanged: (value) => setState(() => lastDay = value),
            ),
          ),
          if (day != null) Text(widget.resultOf(day), style: muted),
          LabeledFormRow(
            label: 'Reason',
            required: widget.reasonRequired,
            field: ShadInputFormField(
              id: ProgrammeEndDateForm.reasonId,
              enabled: widget.enabled,
              keyboardType: TextInputType.text,
              maxLength: ProgrammeEndDateFormValidators.reasonMaxLength,
              placeholder: const Text('Why the end date is changing'),
              validator: (value) => ProgrammeEndDateFormValidators.reason(
                value,
                required: widget.reasonRequired,
              ),
            ),
          ),
          if (error != null)
            Text(
              error,
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.destructive,
              ),
            ),
        ],
      ),
    );
  }
}
