import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;

/// Why a test that needs local and UTC days to differ is skipped, or null
/// when this machine's time zone is far enough from UTC for one to exist.
String? get skipUnlessDayApart =>
    DateTime(2026, 10, 19).timeZoneOffset.inMinutes.abs() >= 60
    ? null
    : 'needs a time zone at least an hour from UTC';

/// A time of day whose local date and UTC date differ in this time zone:
/// half past midnight east of UTC, half past eleven at night west of it.
ShadTimeOfDay get dayApartTime => ShadTimeOfDay(
  hour: DateTime(2026, 10, 19).timeZoneOffset.isNegative ? 23 : 0,
  minute: 30,
  second: 0,
);

/// The `BYDAY` code of the UTC weekday [instant] falls on.
String utcByDay(DateTime instant) => const [
  'MO',
  'TU',
  'WE',
  'TH',
  'FR',
  'SA',
  'SU',
][instant.toUtc().weekday - 1];
