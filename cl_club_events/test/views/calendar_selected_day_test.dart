// cl_calendar seeds the calendar's selection with DateTime.now().toUtc().
// Around local midnight its UTC date is a day off the viewer's, so today's
// sessions were listed under the wrong day (club_client#300). The tests need
// a time zone at least an hour from UTC; run with TZ=Asia/Kolkata or
// TZ=America/Los_Angeles.
import 'package:cl_club_events/src/utils/calendar_selected_day.dart';
import 'package:cl_club_events/src/views/my_events_calendar_view.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/day_apart.dart';
import '../support/staff_calendar_fixtures.dart';

void main() {
  // Half past midnight east of UTC, half past eleven west of it: a moment
  // whose UTC date is not its local date.
  final selectedLocal = DateTime(2026, 10, 24, dayApartTime.hour, 30);
  final selectedUtc = selectedLocal.toUtc();
  final localDay = DateTime(2026, 10, 24);
  final sessionUtc = selectedLocal.add(const Duration(minutes: 15)).toUtc();

  test(
    'Issue 300: the selected day is the local date of the selected moment',
    () {
      expect(selectedLocalDay(selectedUtc), localDay);
      expect(selectedLocalDay(selectedLocal), localDay);
    },
    skip: skipUnlessDayApart,
  );

  test(
    "Issue 300: My Calendar lists today's session when the selection is a "
    'UTC moment on the previous or next UTC day',
    () {
      final view = MyEventsCalendarView(
        currentUser: UserPrivate(
          username: 'member300',
          displayName: 'member300',
          status: UserStatus.active,
          isSuperAdmin: false,
          roles: const UserRoles(),
          createdAtUtc: DateTime.utc(2024),
        ),
        targetUsername: 'member300',
        viewingSelf: true,
        onHome: () {},
      );

      final list = view.buildDayOccurrences(
        [calendarOccurrence(1, sessionUtc)],
        selectedUtc,
        (from: DateTime(2026, 10), to: DateTime(2026, 11)),
      );

      expect(list, isA<ListView>());
    },
    skip: skipUnlessDayApart,
  );
}
