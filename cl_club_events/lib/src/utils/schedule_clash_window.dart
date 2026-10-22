import 'package:shadcn_ui/shadcn_ui.dart' show DateFormat;

/// The day of a clashing window, in local time: `Mon 3 Nov 2026`.
final DateFormat scheduleClashDayFormat = DateFormat('EEE d MMM y');

/// The time of day of a clashing window, in local time: `6:00 PM`.
final DateFormat scheduleClashTimeFormat = DateFormat('h:mm a');

/// How the schedule clash dialog shows the window from [startUtc] to
/// [endUtc], in local time: `Mon 3 Nov 2026, 6:00 PM – 7:30 PM`, with the
/// end's day too when it ends on another day.
String scheduleClashWindowLabel(DateTime startUtc, DateTime endUtc) {
  final start = startUtc.toLocal();
  final end = endUtc.toLocal();
  final startDay = scheduleClashDayFormat.format(start);
  final endDay = scheduleClashDayFormat.format(end);
  final from = '$startDay, ${scheduleClashTimeFormat.format(start)}';
  final to = endDay == startDay
      ? scheduleClashTimeFormat.format(end)
      : '$endDay, ${scheduleClashTimeFormat.format(end)}';
  return '$from – $to';
}
