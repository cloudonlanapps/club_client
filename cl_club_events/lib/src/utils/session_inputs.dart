import 'package:club_sdk_2/club_sdk_2.dart' show EventSession;
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;
import 'package:ui_lib/ui_lib.dart' show SessionInput;

/// SDK ↔ form translation of an occurrence's named sessions, shared by the
/// camp schedule editor and the timetable editor.
///
/// The forms (`SessionSplitField`) speak `HH:MM` start / end pairs walked
/// from the occurrence's start; the SDK speaks durations.

/// `HH:MM` for [minutes] past midnight.
String formatSessionHM(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

/// Minutes past midnight of an `HH:MM` string, or `null` when malformed.
int? parseSessionHM(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}

/// The length of [session] in minutes; 0 when malformed or reversed.
int sessionInputMinutes(SessionInput session) {
  final start = parseSessionHM(session.startTime);
  final end = parseSessionHM(session.endTime);
  if (start == null || end == null) return 0;
  return end >= start ? end - start : 0;
}

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
        startTime: formatSessionHM(cursor),
        endTime: formatSessionHM(end),
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
        EventSession(name: s.name, periodMinutes: sessionInputMinutes(s)),
    ];
