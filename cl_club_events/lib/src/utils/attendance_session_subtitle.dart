import 'package:shadcn_ui/shadcn_ui.dart' show DateFormat;

/// The day of a session as the attendance screen names it: weekday, day,
/// month and year, e.g. `Sat 1 Nov 2026` (club_client#413).
final DateFormat attendanceSessionDayFormat = DateFormat('EEE d MMM y');

/// The attendance screen's subtitle for a session starting at [startUtc]:
/// `Attendance · Sat 1 Nov 2026`. The start is an instant, so its day is
/// the viewer's local day.
String attendanceSessionSubtitle(DateTime startUtc) =>
    'Attendance · ${attendanceSessionDayFormat.format(startUtc.toLocal())}';
