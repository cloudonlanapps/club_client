import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/session_input.dart';
import 'session_split_field.dart';

/// `ShadForm` field for one schedule's timetable: the shared
/// [SessionSplitField] over a fixed occurrence length, whose value is the
/// split (empty when the day is one session).
///
/// `scheduleKey` names the schedule being edited: when it changes, the
/// split editor is rebuilt from the field's current value, so switching
/// schedules shows the new schedule's own split.
class EventTimetableSessionsField
    extends ShadFormBuilderField<List<SessionInput>> {
  EventTimetableSessionsField({
    required int totalMinutes,
    required ShadTimeOfDay startTime,
    required Object scheduleKey,
    super.id,
    super.initialValue,
    super.validator,
    super.enabled,
    super.key,
  }) : super(
         builder: (state) => SessionSplitField(
           key: ValueKey<Object>(scheduleKey),
           totalMinutes: totalMinutes,
           startTime: startTime,
           initialSessions: state.value ?? const <SessionInput>[],
           enabled: state.widget.enabled,
           onChanged: state.didChange,
         ),
       );
}
