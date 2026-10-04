import 'package:shadcn_ui/shadcn_ui.dart' show DateFormat;

/// Formatting extensions for UTC [DateTime] values from the SDK.
///
/// All methods convert to local time before formatting, since the SDK
/// returns UTC instants that must be displayed in the user's timezone.
extension DateTimeFormat on DateTime {
  /// Converts to local and formats as "Apr 21, 2026".
  String toLocalDateMedium() => DateFormat.yMMMd().format(toLocal());

  /// Converts to local and formats as "April 21, 2026".
  String toLocalDateLong() => DateFormat.yMMMMd().format(toLocal());

  /// Converts to local and formats as "Apr 21, 2026 4:30 PM".
  String toLocalDateTimeMedium() =>
      DateFormat.yMMMd().add_jm().format(toLocal());

  /// Converts to local and formats as "4:30 PM".
  String toLocalTime() => DateFormat.jm().format(toLocal());
}
