import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'programme_end_date_form_fields.dart';
import 'programme_end_date_form_validators.dart';

/// Pure-UI editor of a programme's end date: the last day it runs on, any
/// day from today (or from the proposed day, when that is earlier), and the
/// reason.
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
    required this.initialValues,
    required this.reasonRequired,
    required this.resultOf,
    this.enabled = true,
    this.proposedLastDay,
    super.key,
  });

  /// Initial values, keyed by the ids of [ProgrammeEndDateFormFields]: the
  /// day the programme ends on now, a local `DateTime` (none when it has no
  /// end), and the reason, a `String`; missing reads empty.
  final Map<String, dynamic> initialValues;

  /// Whether a reason must be given (setting an end where there is none).
  final bool reasonRequired;

  /// What ending on the given day gives, in the host's words.
  final String Function(DateTime day) resultOf;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  /// The day the Last day field opens on, when the host proposes one other
  /// than the end the programme has (ending it from a session: the day
  /// before it). The form is dirty while the chosen day differs from that
  /// end, so a proposed day is saved without being edited.
  ///
  /// A proposed day before today is accepted, as is any day from it on:
  /// ending a programme from a session later today proposes the day of the
  /// session before it (club_client#182).
  final DateTime? proposedLastDay;

  @override
  State<ProgrammeEndDateForm> createState() => ProgrammeEndDateFormState();
}

/// State of [ProgrammeEndDateForm]. Its values are the last day (a local
/// `DateTime`) and the reason (trimmed), under the ids of
/// [ProgrammeEndDateFormFields].
class ProgrammeEndDateFormState extends State<ProgrammeEndDateForm>
    with FormContract<ProgrammeEndDateForm> {
  @override
  bool get focusFirstInvalid => false;

  /// The day the programme ends on now; `null` when it has no end.
  DateTime? get initialDay =>
      widget.initialValues[ProgrammeEndDateFormFields.lastDayId] as DateTime?;

  /// The day the field opens on: the proposed one, else the end.
  DateTime? get openingDay => widget.proposedLastDay ?? initialDay;

  /// The day chosen now.
  late DateTime? lastDay = openingDay;

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
    final initial = initialDay;
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
        ProgrammeEndDateFormFields.lastDayId: openingDay,
        ProgrammeEndDateFormFields.reasonId:
            widget.initialValues[ProgrammeEndDateFormFields.reasonId]
                as String? ??
            '',
      },
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: 'Last day',
            required: true,
            field: CLDatePickerFormField(
              id: ProgrammeEndDateFormFields.lastDayId,
              initialValue: openingDay,
              enabled: widget.enabled,
              yearsBefore: 0,
              validator: (value) => ProgrammeEndDateFormValidators.lastDay(
                value,
                earliest: widget.proposedLastDay,
              ),
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
