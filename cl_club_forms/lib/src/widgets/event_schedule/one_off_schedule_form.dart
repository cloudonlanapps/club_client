import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/one_off_schedule_data.dart';
import '../../models/one_off_schedule_value.dart';
import '../../models/session_input.dart';
import '../event_create/event_create_form_fields.dart' show EventVenueOption;
import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'event_timetable_form_validators.dart';
import 'event_timetable_sessions_field.dart';
import 'event_venue_select_field.dart';
import 'one_off_schedule_fields.dart';
import 'one_off_schedule_form_fields.dart';
import 'one_off_schedule_form_validators.dart';
import 'session_split_field.dart';

/// Pure-UI editor for a one-off event's schedule: its date, start time and
/// duration (the create form's [OneOffScheduleFormField]), its venue, and
/// how its single occurrence is split into sessions. A one-off does not
/// recur, so there is no recurrence input.
///
/// SDK-free: the host seeds [initialValue] and [venues] from its models and
/// drives the form through a `GlobalKey<OneOffScheduleFormState>`
/// ([FormContract]); a server refusal goes back on the field it is about,
/// or inline, with `showErrors`.
class OneOffScheduleForm extends StatefulWidget {
  const OneOffScheduleForm({
    required this.initialValue,
    required this.venues,
    this.notBefore,
    this.enabled = true,
    super.key,
  });

  /// The schedule the form is seeded with: the one-off's current one.
  final OneOffScheduleValue initialValue;

  /// The venues the one-off may move to.
  final List<EventVenueOption> venues;

  /// The earliest start the form accepts: the one-off's current start, since
  /// a one-off may only be postponed. `null` accepts any start.
  final DateTime? notBefore;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<OneOffScheduleForm> createState() => OneOffScheduleFormState();
}

/// State of [OneOffScheduleForm]. Its values are the schedule
/// (`OneOffScheduleData`), the venue id and the sessions
/// (`List<SessionInput>`), under the ids of [OneOffScheduleFormFields].
class OneOffScheduleFormState extends State<OneOffScheduleForm>
    with FormContract<OneOffScheduleForm> {
  @override
  bool get focusFirstInvalid => false;

  /// The start the sessions are walked from while none is chosen.
  static const ShadTimeOfDay midnight = ShadTimeOfDay(
    hour: 0,
    minute: 0,
    second: 0,
  );

  /// The schedule the sessions editor is laid out against.
  late OneOffScheduleData schedule = widget.initialValue.schedule;

  /// The start time the sessions are walked from.
  ShadTimeOfDay get sessionsStart => schedule.startTime ?? midnight;

  /// The schedule as the form holds it now.
  OneOffScheduleValue get currentValue {
    final values = formKey.currentState?.value;
    if (values == null) return widget.initialValue;
    return OneOffScheduleValue(
      schedule:
          values[OneOffScheduleFormFields.scheduleId] as OneOffScheduleData? ??
          schedule,
      venueId: values[OneOffScheduleFormFields.venueId] as int?,
      sessions: List<SessionInput>.from(
        values[OneOffScheduleFormFields.sessionsId] as List? ?? const [],
      ),
    );
  }

  /// The postpone-only rule: the new start is not before
  /// [OneOffScheduleForm.notBefore].
  @override
  String? crossFieldError(Map<String, dynamic> values) =>
      OneOffScheduleFormValidators.notEarlier(
        currentValue.schedule,
        widget.notBefore,
      );

  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) {
    final value = currentValue;
    return {
      OneOffScheduleFormFields.scheduleId: value.schedule,
      OneOffScheduleFormFields.venueId: value.venueId,
      OneOffScheduleFormFields.sessionsId: value.sessions,
    };
  }

  /// Whether the schedule differs from the one the form was seeded with.
  @override
  bool get isDirty => currentValue != widget.initialValue;

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
      OneOffScheduleFormFields.sessionsId,
      durationChanged
          ? const <SessionInput>[]
          : SessionSplitField.walkedFrom(current, sessionsStart),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.initialValue;
    return ShadForm(
      key: formKey,
      initialValue: {
        OneOffScheduleFormFields.scheduleId: initial.schedule,
        OneOffScheduleFormFields.venueId: initial.venueId,
        OneOffScheduleFormFields.sessionsId: initial.sessions,
      },
      child: FormBody(
        error: formError,
        children: [
          OneOffScheduleFormField(
            id: OneOffScheduleFormFields.scheduleId,
            initialValue: initial.schedule,
            enabled: widget.enabled,
            validator: OneOffScheduleFormField.aggregateValidator,
            onChanged: onScheduleChanged,
          ),
          EventVenueSelectField(
            id: OneOffScheduleFormFields.venueId,
            venues: widget.venues,
            initialValue: initial.venueId,
            enabled: widget.enabled,
            validator: OneOffScheduleFormValidators.venue,
          ),
          LabeledFormRow(
            label: 'Sessions',
            field: EventTimetableSessionsField(
              id: OneOffScheduleFormFields.sessionsId,
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
        ],
      ),
    );
  }
}
