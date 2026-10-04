import 'package:shadcn_ui/shadcn_ui.dart' show DateFormat;

/// A statement or package date, local: "Tue 23 Sep".
String creditDay(DateTime utc) => DateFormat('EEE d MMM').format(utc.toLocal());

/// A validity or trial range, local: "1 Sep – 30 Nov 2026".
String creditRange(DateTime fromUtc, DateTime untilUtc) {
  final from = fromUtc.toLocal();
  final until = untilUtc.toLocal();
  final left = from.year == until.year
      ? DateFormat('d MMM').format(from)
      : DateFormat('d MMM yyyy').format(from);
  return '$left – ${DateFormat('d MMM yyyy').format(until)}';
}

/// Whether two instants fall on different local days.
bool differentLocalDay(DateTime a, DateTime b) {
  final x = a.toLocal();
  final y = b.toLocal();
  return x.year != y.year || x.month != y.month || x.day != y.day;
}
