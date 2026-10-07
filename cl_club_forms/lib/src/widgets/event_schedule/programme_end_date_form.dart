import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'programme_end_date_form_fields.dart';
import 'programme_end_date_form_validators.dart';

/// Pure-UI editor of a programme's end date: the last day it runs on, any
/// day from today, and the reason.
///
/// Under the day the form states what the choice gives, as the host words
/// it in [resultOf] (e.g. `Last session: Sat 14 Nov 2026.`), before
/// anything is saved.
///
/// SDK-free: the host drives the form through a
/// `GlobalKey<ProgrammeEndDateFormState>` ([FormContract]), reads
/// [ProgrammeEndDateFormState.reason] for an action that needs only the
/// reason, and shows a refusal with `showErrors`.
class ProgrammeEndDateForm extends StatefulWidget {
  const ProgrammeEndDateForm({
    required this.reasonRequired,
    required this.resultOf,
    this.initialDay,
    this.enabled = true,
    super.key,
  });

  /// The day the programme ends on now; `null` when it has no end.
  final DateTime? initialDay;

  /// Whether a reason must be given (setting an end where there is none).
  final bool reasonRequired;

  /// What ending on the given day gives, in the host's words.
  final String Function(DateTime day) resultOf;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<ProgrammeEndDateForm> createState() => ProgrammeEndDateFormState();
}

/// State of [ProgrammeEndDateForm]. Its values are the last day (a local
/// `DateTime`) and the reason (trimmed), under the ids of
/// [ProgrammeEndDateFormFields].
class ProgrammeEndDateFormState extends State<ProgrammeEndDateForm>
    with FormContract<ProgrammeEndDateForm> {
  /// The day chosen now.
  late DateTime? lastDay = widget.initialDay;

  /// The reason typed so far, trimmed.
  String get reason =>
      (formKey.currentState?.value[ProgrammeEndDateFormFields.reasonId]
                  as String? ??
              '')
          .trim();

  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    ProgrammeEndDateFormFields.lastDayId:
        values[ProgrammeEndDateFormFields.lastDayId] as DateTime,
    ProgrammeEndDateFormFields.reasonId: reason,
  };

  /// Whether the chosen day differs from the one the programme ends on now.
  @override
  bool get isDirty {
    final day =
        formKey.currentState?.value[ProgrammeEndDateFormFields.lastDayId]
            as DateTime?;
    final initial = widget.initialDay;
    if (day == null || initial == null) return day != initial;
    return !DateUtils.isSameDay(day, initial);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final day = lastDay;
    return ShadForm(
      key: formKey,
      initialValue: {
        ProgrammeEndDateFormFields.lastDayId: widget.initialDay,
        ProgrammeEndDateFormFields.reasonId: '',
      },
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: 'Last day',
            required: true,
            field: CLDatePickerFormField(
              id: ProgrammeEndDateFormFields.lastDayId,
              initialValue: widget.initialDay,
              enabled: widget.enabled,
              yearsBefore: 0,
              validator: ProgrammeEndDateFormValidators.lastDay,
              onChanged: (value) => setState(() => lastDay = value),
            ),
          ),
          if (day != null)
            Text(
              widget.resultOf(day),
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
          LabeledFormRow(
            label: 'Reason',
            required: widget.reasonRequired,
            field: ShadInputFormField(
              id: ProgrammeEndDateFormFields.reasonId,
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
        ],
      ),
    );
  }
}
