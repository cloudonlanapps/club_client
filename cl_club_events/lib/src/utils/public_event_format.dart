import 'package:club_sdk_2/club_sdk_2.dart' show EventType;

/// The currency the club charges in.
///
/// The server used to send `currency` alongside every fee and no longer does.
/// The club is single-currency, so this is a constant rather than a field that
/// would only ever hold one value.
const String kCurrencySymbol = '₹';

/// English month names, January first.
const List<String> kMonthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// rrule `BYDAY` codes and their short day names.
const Map<String, String> kRruleDayNames = {
  'MO': 'Mon',
  'TU': 'Tue',
  'WE': 'Wed',
  'TH': 'Thu',
  'FR': 'Fri',
  'SA': 'Sat',
  'SU': 'Sun',
};

/// The name of [month] (1-12).
String monthName(int month) => kMonthNames[month - 1];

/// e.g. "4 May 2026".
String formatLongDate(DateTime date) =>
    '${date.day} ${monthName(date.month)} ${date.year}';

/// [number] grouped the Indian way: the last three digits, then pairs
/// (`150000` → `1,50,000`). Used for the headline fee.
String formatIndianGrouping(int number) {
  final str = number.toString();
  final result = StringBuffer();
  var count = 0;

  for (var i = str.length - 1; i >= 0; i--) {
    if (count == 3 || (count > 3 && (count - 3).isEven)) {
      result.write(',');
    }
    result.write(str[i]);
    count++;
  }

  return result.toString().split('').reversed.join();
}

/// [number] grouped in thousands (`150000` → `150,000`). Used in the fee
/// tables.
String formatThousands(int number) {
  return number.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
}

/// A time of day, e.g. "4:30 PM", "10:00 AM".
///
/// Minutes are always shown. They used to be dropped on the hour, which was
/// invisible while timings were server-sent strings and is not now that both
/// ends of a range are derived: "7:30 AM - 10 AM" reads as a typo next to the
/// club's own "7:30 AM - 10:00 AM".
String formatTimeOnly(DateTime dateTime) {
  final hour = dateTime.hour;
  final period = hour >= 12 ? 'PM' : 'AM';
  final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  final minuteStr = dateTime.minute.toString().padLeft(2, '0');
  return '$hour12:$minuteStr $period';
}

/// The number of occurrences an rrule's `COUNT` names, or null.
int? rruleCount(String? rrule) {
  if (rrule == null || !rrule.contains('COUNT=')) return null;
  final match = RegExp(r'COUNT=(\d+)').firstMatch(rrule);
  return match == null ? null : int.tryParse(match.group(1)!) ?? 1;
}

/// A schedule phrase from an rrule: its days ("Mon, Tue"), "Daily", or
/// "Weekly"; null when it says none of these.
String? deriveScheduleFromRrule(String? rrule) {
  if (rrule == null || rrule.isEmpty) return null;

  final byDayMatch = RegExp('BYDAY=([A-Z,]+)').firstMatch(rrule);
  if (byDayMatch != null) {
    return byDayMatch
        .group(1)!
        .split(',')
        .map((abbr) => kRruleDayNames[abbr] ?? abbr)
        .join(', ');
  }
  if (rrule.contains('FREQ=DAILY')) return 'Daily';
  if (rrule.contains('FREQ=WEEKLY')) return 'Weekly';
  return null;
}

/// The first `BYDAY` code of an rrule ("SA" for `FREQ=WEEKLY;BYDAY=SA,SU`).
String? firstRruleDay(String? rrule) {
  if (rrule == null) return null;
  return RegExp('BYDAY=([A-Z]{2})').firstMatch(rrule)?.group(1);
}

/// A duration phrase from an occurrence's window: a programme's clock range,
/// or how long a camp or one-off lasts.
String deriveDurationFromTimes(
  DateTime startTime,
  DateTime endTime,
  EventType type,
) {
  if (type == EventType.programme) {
    return '${formatTimeOnly(startTime)} - ${formatTimeOnly(endTime)}';
  }

  final durationHours = endTime.difference(startTime).inHours;
  final durationMinutes = endTime.difference(startTime).inMinutes % 60;

  if (durationHours >= 24) {
    final days = (durationHours / 24).ceil();
    return '$days ${days == 1 ? 'day' : 'days'}';
  } else if (durationHours > 0) {
    if (durationMinutes > 0) {
      return '$durationHours hr $durationMinutes min';
    }
    return '$durationHours ${durationHours == 1 ? 'hour' : 'hours'}';
  } else {
    return '$durationMinutes min';
  }
}
