import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/event_timetable_value.dart';
import '../../models/session_input.dart';
import '../../models/timetable_schedule_option.dart';
import 'event_timetable_form_validators.dart';
import 'event_timetable_sessions_field.dart';
import 'labeled_form_row.dart';

/// Pure-UI editor that corrects an event's timetable — how each occurrence
/// is split into named sessions — without moving any date.
///
/// [schedules] are the schedules the admin may correct: one for a camp or
/// one-off, one per timetable period for a programme. With more than one, a
/// picker chooses which (the latest by default), and switching shows that
/// schedule's own split over its own occurrence length.
///
/// SDK-free: the host seeds [schedules] from its models, drives the form
/// through a `GlobalKey<EventTimetableFormState>` — [EventTimetableFormState
/// .validate] from Save, [EventTimetableFormState.isDirty] for no-op
/// detection — and shows a server refusal of the split against the form with
/// [EventTimetableFormState.showSessionsError].
class EventTimetableForm extends StatefulWidget {
  const EventTimetableForm({
    required this.schedules,
    this.initialScheduleIndex,
    this.note,
    this.enabled = true,
    super.key,
  }) : assert(schedules.length > 0, 'at least one schedule');

  /// Field id of the schedule picker (an index into [schedules]).
  static const String scheduleId = 'schedule';

  /// Field id of the sessions editor.
  static const String sessionsId = 'sessions';

  /// The schedules that may be corrected, oldest first.
  final List<TimetableScheduleOption> schedules;

  /// The schedule shown first; the last (latest) when `null`.
  final int? initialScheduleIndex;

  /// A muted line under the editor saying what a correction does.
  final String? note;

  /// Whether the fields accept input.
  final bool enabled;

  @override
  State<EventTimetableForm> createState() => EventTimetableFormState();
}

class EventTimetableFormState extends State<EventTimetableForm> {
  final formKey = GlobalKey<ShadFormState>();

  /// Index into `EventTimetableForm.schedules` of the schedule being edited.
  late int selectedIndex =
      widget.initialScheduleIndex ?? widget.schedules.length - 1;

  /// The schedule being edited.
  TimetableScheduleOption get selectedSchedule =>
      widget.schedules[selectedIndex];

  List<SessionInput> get currentSessions =>
      formKey.currentState?.value[EventTimetableForm.sessionsId]
          as List<SessionInput>? ??
      selectedSchedule.sessions;

  /// Validates the split and returns it with the chosen schedule, else
  /// `null` (the sessions field shows why).
  EventTimetableValue? validate() {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return null;
    return EventTimetableValue(
      scheduleId: selectedSchedule.id,
      sessions: currentSessions,
    );
  }

  /// Whether the chosen schedule's split differs from its current one.
  bool get isDirty => !listEquals(currentSessions, selectedSchedule.sessions);

  /// Shows [message] against the sessions field, e.g. when the server
  /// refuses the split.
  void showSessionsError(String message) => formKey.currentState?.setFieldError(
    EventTimetableForm.sessionsId,
    message,
  );

  void selectSchedule(int? index) {
    if (index == null || index == selectedIndex) return;
    setState(() => selectedIndex = index);
    formKey.currentState?.setFieldValue<List<SessionInput>>(
      EventTimetableForm.sessionsId,
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
        EventTimetableForm.scheduleId: selectedIndex,
        EventTimetableForm.sessionsId: schedule.sessions,
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          if (widget.schedules.length > 1)
            LabeledFormRow(
              label: 'Schedule',
              field: ShadSelectFormField<int>(
                id: EventTimetableForm.scheduleId,
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
              id: EventTimetableForm.sessionsId,
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
