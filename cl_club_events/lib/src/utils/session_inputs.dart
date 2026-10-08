import 'package:cl_club_forms/cl_club_forms.dart'
    show SessionInput, SessionSplitField;
import 'package:club_sdk_2/club_sdk_2.dart' show EventSession;
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;

/// SDK ↔ form translation of an occurrence's named sessions, shared by the
/// camp schedule editor and the timetable editor.
///
/// The forms (`SessionSplitField`) speak `HH:MM` start / end pairs walked
/// from the occurrence's start; the SDK speaks durations. The times are
/// written and read with the form's own helpers, so a session that ends
/// after midnight wraps to the next day and keeps its length.

/// The form's split of an occurrence starting at [start] from the SDK's
/// [sessions]. A single session is the trivial "no split" case the form
/// represents as empty.
List<SessionInput> sessionInputsFromEventSessions(
  List<EventSession>? sessions,
  ShadTimeOfDay start,
) {
  if (sessions == null || sessions.length < 2) return const <SessionInput>[];
  final result = <SessionInput>[];
  var cursor = start.hour * 60 + start.minute;
  for (final s in sessions) {
    final end = cursor + s.periodMinutes;
    result.add(
      SessionInput(
        name: s.name,
        startTime: SessionSplitField.formatHM(cursor),
        endTime: SessionSplitField.formatHM(end),
      ),
    );
    cursor = end;
  }
  return result;
}

/// The SDK's sessions from the form's split.
List<EventSession> eventSessionsFromSessionInputs(List<SessionInput> inputs) =>
    [
      for (final s in inputs)
        EventSession(
          name: s.name,
          periodMinutes: SessionSplitField.sessionMinutes(s),
        ),
    ];
