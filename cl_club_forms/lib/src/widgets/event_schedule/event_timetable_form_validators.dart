import '../../models/session_input.dart';
import 'session_split_field.dart';

/// Pure validators for `EventTimetableForm`.
class EventTimetableFormValidators {
  const EventTimetableFormValidators._();

  /// Shown when the sessions do not add up to the occurrence length — by
  /// this validator, and by the host when the server refuses the split
  /// (`INVALID_SESSIONS_TOTAL`).
  static const String totalMismatchMessage =
      'The sessions must add up to the length of the occurrence.';

  /// `null` when [sessions] is empty (one undivided session) or adds up to
  /// [totalMinutes]; else [totalMismatchMessage].
  static String? sessionsTotal(List<SessionInput>? sessions, int totalMinutes) {
    if (sessions == null || sessions.isEmpty) return null;
    final sum = sessions.fold<int>(
      0,
      (total, s) => total + SessionSplitField.sessionMinutes(s),
    );
    return sum == totalMinutes ? null : totalMismatchMessage;
  }
}
