import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The day currently displayed by the dashboard "today" panels.
///
/// Returns local-time midnight of today. Panels (`Today's Events`,
/// `My Events`, `Public Events`) all watch this single provider and derive
/// their `[from, to)` query range via [startOfDayLocal] / [endOfDayLocal].
///
/// This is intentionally a plain `Provider`, not a `StateProvider`: panels
/// are fixed to today and carry no in-app date selection. Refreshes (e.g.
/// across midnight) come from invalidating this provider.
final Provider<DateTime> selectedDayProvider = Provider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Returns midnight (local) of [date].
DateTime startOfDayLocal(DateTime date) =>
    DateTime(date.year, date.month, date.day);

/// Returns midnight + 1 day (local) of [date] — exclusive end-of-day bound.
///
/// Used as the upper bound of a half-open range: `start <= occurrence < end`.
/// `DateTime`'s constructor normalizes overflow, so `day + 1` rolls over the
/// month/year correctly (Jan 31 → Feb 1, Dec 31 → Jan 1 next year).
DateTime endOfDayLocal(DateTime date) =>
    DateTime(date.year, date.month, date.day + 1);
