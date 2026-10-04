/// Key for the occurrences notifier family provider.
///
/// Uses plain DateTime start/end instead of CalendarViewRange
/// to avoid depending on cl_calendar.
typedef ClOccurrencesNotifierKey = ({
  DateTime startUtc,
  DateTime endUtc,
});
