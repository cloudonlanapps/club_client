// Run with TZ=Asia/Kolkata to see the failure this guards against: the
// session below is 01:30 local on 1 Nov, which is 2026-10-31T20:00Z there.
// In UTC the instant and the local month agree and the test passes
// trivially.
import 'package:cl_club_events/cl_club_events.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart' hide Visibility;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk show Visibility;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _username = 'member209';
const _title = 'Issue 209 Camp';

UserPrivate _user() => UserPrivate(
  username: _username,
  displayName: 'Member',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(),
  createdAtUtc: DateTime.utc(2026),
);

Event _event() => Event(
  id: 7,
  title: _title,
  description: '',
  type: EventType.camp,
  visibility: sdk.Visibility.public,
  venueId: 1,
  startTimeUtc: DateTime.utc(2026, 10),
  endTimeUtc: DateTime.utc(2026, 10, 1, 1),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

class _StaticMyEvents extends ClMyEventsMasterNotifier {
  @override
  Future<List<Event>> build(String arg) async => [_event()];
}

/// Taps the month arrows from today's month to [year]/[month].
Future<void> _goToMonth(WidgetTester tester, int year, int month) async {
  final now = DateTime.now();
  final delta = (year * 12 + month) - (now.year * 12 + now.month);
  final arrow = delta > 0 ? Icons.chevron_right : Icons.chevron_left;
  for (var i = 0; i < delta.abs(); i++) {
    await tester.tap(find.byIcon(arrow));
    await tester.pump();
  }
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets(
    'Issue 209: a session early on the 1st is in that local month',
    (tester) async {
      final sessionUtc = DateTime(2026, 11, 1, 1, 30).toUtc();
      final record = MyAttendanceRecord(
        eventId: 7,
        occurrenceTimeUtc: sessionUtc,
        membername: _username,
        status: AttendanceStatus.present,
        recordedAtUtc: sessionUtc,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clMyEventsMasterProvider.overrideWith(_StaticMyEvents.new),
            // Serves the record when the asked range holds it, as the
            // server does.
            clMyAttendanceListProvider.overrideWith(
              (ref, key) async => [
                if (!sessionUtc.isBefore(key.fromTimeUtc) &&
                    sessionUtc.isBefore(key.toTimeUtc))
                  record,
              ],
            ),
          ],
          child: ShadApp(
            home: Scaffold(
              body: MyEventsAttendanceView(
                currentUser: _user(),
                targetUsername: _username,
                onHome: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await _goToMonth(tester, 2026, 11);
      expect(find.text('November 2026'), findsOneWidget);
      expect(find.text(_title), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();
      await tester.pump();
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text(_title), findsNothing);
    },
  );
}
