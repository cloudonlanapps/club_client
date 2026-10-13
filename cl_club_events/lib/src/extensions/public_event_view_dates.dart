import '../models/public/public_event_view.dart';
import '../utils/camp_rest_days.dart';
import '../utils/public_event_format.dart';

/// The call-to-action state of a public event page.
abstract final class PublicEventCtaState {
  /// Open for registration.
  static const String available = 'available';

  /// Registration has closed; the event has not finished.
  static const String closed = 'closed';

  /// Every occurrence has finished.
  static const String completed = 'completed';
}

/// Dates, fees and registration state of a public event, as display text.
extension PublicEventViewDates on PublicEventView {
  /// The [PublicEventCtaState] key.
  ///
  /// With the marketing module off there is no deadline to have passed, so a
  /// live event reads as available — which is the honest answer: nothing said
  /// registration had closed.
  String get ctaState {
    if (isPast) return PublicEventCtaState.completed;
    if (isRegistrationClosed) return PublicEventCtaState.closed;
    return PublicEventCtaState.available;
  }

  /// Preferred date-range label for camp/oneOff events.
  ///
  /// Uses the marketing [schedule] text when set
  /// (e.g. "4th May - 8th May 2026"), otherwise falls back to the computed
  /// [dateRange] derived from startTimeUtc + rrule COUNT. The server string
  /// is authoritative — the derivation can drift by a day due to timezone
  /// conversion on UTC timestamps.
  String get displayDateRange {
    final text = schedule;
    if (text != null && text.isNotEmpty) return text;
    return dateRange;
  }

  /// Formatted date range (e.g. "15 - 20 April 2026"); a daily rrule's
  /// days held and rest days set the end date ([campSpanDays]).
  ///
  /// SDK emits UTC instants; day/month/year must be read in local time,
  /// otherwise events starting at local midnight (e.g. 4 May 00:00 IST =
  /// 3 May 18:30 UTC) render one day early.
  String get dateRange {
    final startLocal = startTimeUtc.toLocal();

    var endLocal = endTimeUtc.toLocal();
    final span = campSpanDays(rrule, startTimeUtc);
    if (span != null && rrule!.contains('FREQ=DAILY')) {
      endLocal = startLocal.add(Duration(days: span - 1));
    }

    final startDay = startLocal.day;
    final endDay = endLocal.day;
    final year = startLocal.year;

    if (startDay == endDay && startLocal.month == endLocal.month) {
      return '$startDay ${monthName(startLocal.month)} $year';
    }
    if (startLocal.month == endLocal.month) {
      return '$startDay - $endDay ${monthName(startLocal.month)} $year';
    }
    return '$startDay ${monthName(startLocal.month)} - $endDay '
        '${monthName(endLocal.month)} $year';
  }

  /// The headline fee (e.g. "15,000/-"), or empty when there is none.
  String get formattedFees {
    final feesValue = fees;
    if (feesValue == null) return '';
    return '${formatIndianGrouping(feesValue)}/-';
  }

  /// The registration deadline (e.g. "4 May 2026"), or empty.
  ///
  /// SDK emits UTC instants; convert to local before extracting day/month/year
  /// so a deadline at e.g. 2026-05-04 00:00 IST (= 2026-05-03 18:30 UTC)
  /// doesn't render as one day earlier.
  String get formattedDeadline {
    final deadline = registrationDeadline;
    if (deadline == null) return '';
    return formatLongDate(deadline.toLocal());
  }
}
