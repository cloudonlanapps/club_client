import '../../../constants/evaluation_strings.dart';

/// Static, SDK-free validators of an evaluation's review period.
abstract final class EvaluationPeriodValidators {
  /// The message for a period that ends after today.
  static const String futureMessage = EvaluationStrings.periodFuture;

  /// The period from [start] to [end]: both dates or neither, the start on
  /// or before the end (a one-day period is fine), and the end no later
  /// than [today] (the current day when not given). Returns the message, or
  /// `null` when valid.
  static String? period(DateTime? start, DateTime? end, {DateTime? today}) {
    if ((start == null) != (end == null)) return EvaluationStrings.periodBoth;
    if (start == null || end == null) return null;
    if (dayOf(end).isBefore(dayOf(start))) return EvaluationStrings.periodOrder;
    if (dayOf(end).isAfter(dayOf(today ?? DateTime.now()))) {
      return futureMessage;
    }
    return null;
  }

  /// [date]'s calendar day, without its time.
  static DateTime dayOf(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
