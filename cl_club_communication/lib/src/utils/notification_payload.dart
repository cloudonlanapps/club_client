/// Readers for the loosely typed values in a notification's payload `data`.
///
/// The server writes JSON, so a number may arrive as an `int`, a `double`
/// or a string, and any key may be absent. Each reader returns a neutral
/// value (`''` or `null`) instead of throwing, so a malformed payload still
/// renders a row.
library;

import 'package:shadcn_ui/shadcn_ui.dart' show DateFormat;

/// The pattern notification rows use for a single day.
const String kNotificationDayPattern = 'dd-MM-yyyy';

/// [v] as a string; `''` when absent.
String payloadString(Object? v) => v == null ? '' : v.toString();

/// [v] as an int; `null` when absent or not a number.
int? payloadInt(Object? v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

/// ASCII punctuation, every character of which markdown lets a backslash
/// escape.
final RegExp kMarkdownPunctuation = RegExp(r'[!-/:-@\[-`{-~]');

/// [text] escaped so a notification body, which renders as markdown, shows
/// it literally. For text from outside the club, such as an inquirer's
/// name, so it cannot bring in a link or a remote image.
String markdownLiteral(String text) =>
    text.replaceAllMapped(kMarkdownPunctuation, (m) => '\\${m[0]}');

/// The local day of a UTC epoch-milliseconds value [raw], formatted with
/// [kNotificationDayPattern]; `''` when absent or not a number.
String payloadDateText(Object? raw) {
  final ms = payloadInt(raw);
  if (ms == null) return '';
  final day = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
  return DateFormat(kNotificationDayPattern).format(day);
}
