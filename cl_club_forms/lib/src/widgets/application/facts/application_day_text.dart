import '../application_form_strings.dart';

/// Shows a day as the template stores it (`2026-11-19`) the way the forms
/// show it (`19 Nov 2026`).
abstract final class ApplicationDayText {
  /// [day] as shown; [day] itself when it is no stored day.
  static String of(String day) {
    final date = DateTime.tryParse(day);
    if (date == null) return day;
    return '${date.day} ${ApplicationFormStrings.months[date.month - 1]} '
        '${date.year}';
  }

  /// [date]'s day as the template stores it.
  static String stored(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
