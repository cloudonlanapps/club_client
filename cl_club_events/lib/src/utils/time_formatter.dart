/// Formats a time of day for display.
/// Converts UTC DateTime to local and formats as "HH:MM AM/PM".
String formatTimeOfDay(DateTime dateTimeUtc) {
  final local = dateTimeUtc.toLocal();
  final hour = local.hour;
  final minute = local.minute;

  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  final displayMinute = minute.toString().padLeft(2, '0');

  return '$displayHour:$displayMinute $period';
}

/// Formats a time range for display.
/// Returns "HH:MM AM - HH:MM PM" format.
String formatTimeRange(DateTime startUtc, DateTime endUtc) {
  return '${formatTimeOfDay(startUtc)} - ${formatTimeOfDay(endUtc)}';
}
