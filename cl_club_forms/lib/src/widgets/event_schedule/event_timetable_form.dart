import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/session_input.dart';
import '../../models/timetable_schedule_option.dart';
import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'event_timetable_form_fields.dart';
import 'event_timetable_form_validators.dart';
import 'event_timetable_sessions_field.dart';

/// Pure-UI editor that corrects an event's timetable — how each occurrence
/// is split into named sessions — without moving any date.
///
/// [schedules] are the schedules the admin may correct: one for a camp or
/// one-off, one per timetable period for a programme. With more than one, a
/// picker chooses which (the latest by default), and switching shows that
/// schedule's own split over its own occurrence length.
///
/// SDK-free: the host seeds [schedules] from its models and drives the form
/// through a `GlobalKey<EventTimetableFormState>` ([FormContract]); a server
/// refusal of the split goes back on the sessions field with `showErrors`.
class EventTimetableForm extends StatefulWidget {
  const EventTimetableForm({
    required this.schedules,
    this.initialScheduleIndex,
    this.note,
    this.enabled = true,
    super.key,
  }) : assert(schedules.length > 0, 'at least one schedule');

  /// The schedules that may be corrected, oldest first.
  final List<TimetableScheduleOption> schedules;

  /// The schedule shown first; the last (latest) when `null`.
  final int? initialScheduleIndex;

  /// A muted line under the editor saying what a correction does.
  final String? note;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<EventTimetableForm> createState() => EventTimetableFormState();
}

/// State of [EventTimetableForm]. Its values are the chosen schedule's id
/// (`int?`) under [EventTimetableFormFields.scheduleId] and the split
/// (`List<SessionInput>`, empty for one undivided session) under
/// [EventTimetableFormFields.sessionsId].
class EventTimetableFormState extends State<EventTimetableForm>
    with FormContract<EventTimetableForm> {
  @override
  bool get focusFirstInvalid => false;

  /// Index into `EventTimetableForm.schedules` of the schedule being edited.
  late int selectedIndex =
      widget.initialScheduleIndex ?? widget.schedules.length - 1;

  /// The schedule being edited.
  TimetableScheduleOption get selectedSchedule =>
      widget.schedules[selectedIndex];

  /// The split as the form holds it now.
  List<SessionInput> get currentSessions =>
      formKey.currentState?.value[EventTimetableFormFields.sessionsId]
          as List<SessionInput>? ??
      selectedSchedule.sessions;

  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    EventTimetableFormFields.scheduleId: selectedSchedule.id,
    EventTimetableFormFields.sessionsId: currentSessions,
  };

  /// Whether the chosen schedule's split differs from its current one.
  @override
  bool get isDirty => !listEquals(currentSessions, selectedSchedule.sessions);

  /// Shows the split of the schedule at [index] in place of the present one.
  void selectSchedule(int? index) {
    if (index == null || index == selectedIndex) return;
    setState(() => selectedIndex = index);
    formKey.currentState?.setFieldValue<List<SessionInput>>(
      EventTimetableFormFields.sessionsId,
      selectedSchedule.sessions,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final schedule = selectedSchedule;
    final note = widget.note;
    return ShadForm(
      key: formKey,
      initialValue: {
        EventTimetableFormFields.scheduleId: selectedIndex,
        EventTimetableFormFields.sessionsId: schedule.sessions,
      },
      child: FormBody(
        error: formError,
        children: [
          if (widget.schedules.length > 1)
            LabeledFormRow(
              label: 'Schedule',
              field: ShadSelectFormField<int>(
                id: EventTimetableFormFields.scheduleId,
                initialValue: selectedIndex,
                enabled: widget.enabled,
                options: [
                  for (var i = 0; i < widget.schedules.length; i++)
                    ShadOption(
                      value: i,
                      child: Text(widget.schedules[i].label),
                    ),
                ],
                selectedOptionBuilder: (context, index) =>
                    Text(widget.schedules[index].label),
                onChanged: selectSchedule,
              ),
            ),
          LabeledFormRow(
            label: 'Sessions',
            field: EventTimetableSessionsField(
              id: EventTimetableFormFields.sessionsId,
              scheduleKey: selectedIndex,
              totalMinutes: schedule.totalMinutes,
              startTime: schedule.startTime,
              initialValue: schedule.sessions,
              enabled: widget.enabled,
              validator: (sessions) =>
                  EventTimetableFormValidators.sessionsTotal(
                    sessions,
                    schedule.totalMinutes,
                  ),
            ),
          ),
          if (note != null)
            Text(
              note,
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.mutedForeground,
              ),
            ),
        ],
      ),
    );
  }
}
