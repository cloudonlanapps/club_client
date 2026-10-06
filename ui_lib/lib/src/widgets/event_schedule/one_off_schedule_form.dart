import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/one_off_schedule_data.dart';
import '../../models/one_off_schedule_value.dart';
import '../../models/session_input.dart';
import '../event_create/event_create_form_fields.dart' show EventVenueOption;
import 'event_timetable_form_validators.dart';
import 'event_timetable_sessions_field.dart';
import 'event_venue_select_field.dart';
import 'labeled_form_row.dart';
import 'one_off_schedule_fields.dart';
import 'one_off_schedule_form_validators.dart';
import 'session_split_field.dart';

/// Pure-UI editor for a one-off event's schedule: its date, start time and
/// duration (the create form's [OneOffScheduleFormField]), its venue, and
/// how its single occurrence is split into sessions. A one-off does not
/// recur, so there is no recurrence input.
///
/// SDK-free: the host seeds [initialValue] and [venues] from its models and
/// drives the form through a `GlobalKey<OneOffScheduleFormState>` —
/// [OneOffScheduleFormState.validate] from Save,
/// [OneOffScheduleFormState.isDirty] for no-op detection — and shows a
/// server refusal against the form with
/// [OneOffScheduleFormState.showSessionsError] or
/// [OneOffScheduleFormState.showFormError].
class OneOffScheduleForm extends StatefulWidget {
  const OneOffScheduleForm({
    required this.initialValue,
    required this.venues,
    this.notBefore,
    this.enabled = true,
    super.key,
  });

  /// Field id of the date, start time and duration.
  static const String scheduleId = 'schedule';

  /// Field id of the venue picker.
  static const String venueId = 'venue';

  /// Field id of the sessions editor.
  static const String sessionsId = 'sessions';

  /// The schedule the form is seeded with: the one-off's current one.
  final OneOffScheduleValue initialValue;

  /// The venues the one-off may move to.
  final List<EventVenueOption> venues;

  /// The earliest start the form accepts: the one-off's current start, since
  /// a one-off may only be postponed. `null` accepts any start.
  final DateTime? notBefore;

  /// Whether the fields accept input.
  final bool enabled;

  @override
  State<OneOffScheduleForm> createState() => OneOffScheduleFormState();
}

class OneOffScheduleFormState extends State<OneOffScheduleForm> {
  final formKey = GlobalKey<ShadFormState>();

  /// The form-level message of a failed cross-field rule, shown inline.
  String? formError;

  /// The schedule the sessions editor is laid out against.
  late OneOffScheduleData schedule = widget.initialValue.schedule;

  /// The start time the sessions are walked from.
  ShadTimeOfDay get sessionsStart =>
      schedule.startTime ?? const ShadTimeOfDay(hour: 0, minute: 0, second: 0);

  OneOffScheduleValue get currentValue {
    final values = formKey.currentState?.value;
    if (values == null) return widget.initialValue;
    return OneOffScheduleValue(
      schedule:
          values[OneOffScheduleForm.scheduleId] as OneOffScheduleData? ??
          schedule,
      venueId: values[OneOffScheduleForm.venueId] as int?,
      sessions: List<SessionInput>.from(
        values[OneOffScheduleForm.sessionsId] as List? ?? const [],
      ),
    );
  }

  /// Validates every field and the postpone-only rule, and returns the
  /// edited schedule, else `null` (the fields, or the inline form message,
  /// say why).
  OneOffScheduleValue? validate() {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return null;
    final value = currentValue;
    final error = OneOffScheduleFormValidators.notEarlier(
      value.schedule,
      widget.notBefore,
    );
    setState(() => formError = error);
    return error == null ? value : null;
  }

  /// Whether the schedule differs from the one the form was seeded with.
  bool get isDirty => currentValue != widget.initialValue;

  /// Shows [message] against the sessions field, e.g. when the server
  /// refuses the split.
  void showSessionsError(String message) => formKey.currentState?.setFieldError(
    OneOffScheduleForm.sessionsId,
    message,
  );

  /// Shows [message] as the inline form-level message.
  void showFormError(String message) => setState(() => formError = message);

  /// Keeps the sessions in step with the date, start time and duration: a
  /// new duration resets the split to one session, a new start time moves
  /// the same split to start there.
  void onScheduleChanged(OneOffScheduleData? next) {
    if (next == null || next == schedule) return;
    final durationChanged = next.durationMinutes != schedule.durationMinutes;
    final current = currentValue.sessions;
    setState(() {
      schedule = next;
      formError = null;
    });
    if (current.isEmpty) return;
    formKey.currentState?.setFieldValue<List<SessionInput>>(
      OneOffScheduleForm.sessionsId,
      durationChanged
          ? const <SessionInput>[]
          : SessionSplitField.walkedFrom(current, sessionsStart),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final initial = widget.initialValue;
    final error = formError;
    return ShadForm(
      key: formKey,
      initialValue: {
        OneOffScheduleForm.scheduleId: initial.schedule,
        OneOffScheduleForm.venueId: initial.venueId,
        OneOffScheduleForm.sessionsId: initial.sessions,
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          OneOffScheduleFormField(
            id: OneOffScheduleForm.scheduleId,
            initialValue: initial.schedule,
            enabled: widget.enabled,
            validator: OneOffScheduleFormField.aggregateValidator,
            onChanged: onScheduleChanged,
          ),
          EventVenueSelectField(
            id: OneOffScheduleForm.venueId,
            venues: widget.venues,
            initialValue: initial.venueId,
            enabled: widget.enabled,
            validator: OneOffScheduleFormValidators.venue,
          ),
          LabeledFormRow(
            label: 'Sessions',
            field: EventTimetableSessionsField(
              id: OneOffScheduleForm.sessionsId,
              scheduleKey: (schedule.durationMinutes, sessionsStart),
              totalMinutes: schedule.durationMinutes,
              startTime: sessionsStart,
              initialValue: initial.sessions,
              enabled: widget.enabled,
              validator: (sessions) =>
                  EventTimetableFormValidators.sessionsTotal(
                    sessions,
                    schedule.durationMinutes,
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
