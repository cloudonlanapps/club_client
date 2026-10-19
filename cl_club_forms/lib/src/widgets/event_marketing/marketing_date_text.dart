/// The month names a marketing date is written with.
const List<String> marketingMonthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// [date] as a marketing list shows it: `5 Oct 2026`.
String marketingDateText(DateTime date) =>
    '${date.day} ${marketingMonthNames[date.month - 1]} ${date.year}';
