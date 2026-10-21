import 'dart:async';

import 'package:cl_remote_store/cl_remote_store.dart'
    show clManualRefreshProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The day currently displayed by the dashboard "today" panels.
///
/// Returns local-time midnight of today. Panels (`Today's Events`,
/// `My Events`, `Public Events`) all watch this single provider and derive
/// their `[from, to)` query range via [startOfDayLocal] / [endOfDayLocal].
///
/// This is intentionally a plain `Provider`, not a `StateProvider`: panels
/// are fixed to today and carry no in-app date selection. It turns itself
/// over: a timer set for just after the next local midnight invalidates
/// it, so a dashboard left open overnight moves to the new day. The shell's
/// Refresh (`clManualRefreshProvider`) reads the day again too.
final Provider<DateTime> selectedDayProvider = Provider<DateTime>((ref) {
  ref.watch(clManualRefreshProvider);
  final now = ref.watch(selectedDayClockProvider)();
  final today = DateTime(now.year, now.month, now.day);
  final nextMidnight = DateTime(now.year, now.month, now.day + 1);
  // A second's margin, so the day read when it fires is the new one.
  final turnOver = Timer(
    nextMidnight.difference(now) + const Duration(seconds: 1),
    ref.invalidateSelf,
  );
  ref.onDispose(turnOver.cancel);
  return today;
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

/// The clock [selectedDayProvider] reads; tests override it.
final Provider<DateTime Function()> selectedDayClockProvider =
    Provider<DateTime Function()>((ref) => DateTime.now);
