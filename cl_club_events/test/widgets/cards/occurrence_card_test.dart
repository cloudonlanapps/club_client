import 'package:cl_club_events/src/widgets/cards/attendance_badge.dart';
import 'package:cl_club_events/src/widgets/cards/occurrence_card.dart';
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _username = 'demo_user';
const _eventId = 101;
const _eventTitle = 'U10 Skating Practice';

DateTime _futureUtc(Duration offset) => DateTime.now().toUtc().add(offset);

Occurrence _occurrence({
  required OccurrenceStatus status,
  AttendanceStatus? attendanceStatus,
  DateTime? actualStart,
  DateTime? actualEnd,
  DateTime? originalStart,
}) {
  final start = actualStart ?? _futureUtc(const Duration(hours: 4));
  return Occurrence(
    eventId: _eventId,
    originalStartTimeUtc: originalStart ?? start,
    actualStartTimeUtc: start,
    actualEndTimeUtc: actualEnd ?? _futureUtc(const Duration(hours: 5)),
    status: status,
    venueId: 1,
    attendanceStatus: attendanceStatus,
  );
}

Event _event() => Event(
  id: _eventId,
  title: _eventTitle,
  description: '',
  type: EventType.programme,
  visibility: Visibility.private,
  venueId: 1,
  startTimeUtc: DateTime.now().toUtc(),
  endTimeUtc: DateTime.now().toUtc().add(const Duration(hours: 1)),
  createdAtUtc: DateTime.now().toUtc(),
  updatedAtUtc: DateTime.now().toUtc(),
);

class _StaticMyEventsNotifier extends ClMyEventsMasterNotifier {
  @override
  Future<List<Event>> build(String arg) async => [_event()];
}

class _EmptyMyEventsNotifier extends ClMyEventsMasterNotifier {
  @override
  Future<List<Event>> build(String arg) async => const <Event>[];
}

class _SentinelEventsMasterNotifier extends ClEventsMasterNotifier {
  static int buildCalls = 0;

  @override
  Future<Map<int, Event>> build() async {
    buildCalls++;
    return const <int, Event>{};
  }
}

class _NoAuthNotifier extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => null;
}

final ({DateTime from, DateTime to}) _range = (
  from: DateTime.now().toUtc(),
  to: DateTime.now().toUtc().add(const Duration(days: 30)),
);

/// The member's enrollment in the event, for a card that reads it.
Enrollment _enrollment() => Enrollment(
  id: 1,
  eventId: _eventId,
  membername: _username,
  status: EnrollmentStatus.assigned,
  createdAtUtc: DateTime.utc(2026),
  enrolledAtUtc: DateTime.utc(2026),
);

Future<void> _pumpCard(
  WidgetTester tester, {
  required Occurrence occurrence,
  Enrollment? enrollment,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clMyEventsMasterProvider.overrideWith(_StaticMyEventsNotifier.new),
        authStateProvider.overrideWith(_NoAuthNotifier.new),
        clMyOccurrencesListProvider((
          username: _username,
          fromTimeUtc: _range.from,
          toTimeUtc: _range.to,
        )).overrideWith((ref) async => [occurrence]),
        clMyEnrollmentProvider(
          (username: _username, eventId: _eventId),
        ).overrideWith((ref) async => enrollment),
      ],
      child: ShadApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            child: OccurrenceCard(
              eventId: _eventId,
              occurrenceTime: occurrence.originalStartTimeUtc,
              range: _range,
              username: _username,
              onTap: () {},
            ),
          ),
        ),
      ),
    ),
  );
  // The card resolves Event + Occurrence via async providers; pump
  // a few frames so the overridden providers' build() completes.
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

void main() {
  group('Issue 226: OccurrenceCard layout', () {
    testWidgets('Issue 226: renders resolved event title', (tester) async {
      await _pumpCard(
        tester,
        occurrence: _occurrence(status: OccurrenceStatus.scheduled),
      );
      expect(find.textContaining(_eventTitle), findsOneWidget);
    });

    testWidgets('Issue 226: cancelled occurrence shows Cancelled label', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        occurrence: _occurrence(status: OccurrenceStatus.cancelled),
      );
      expect(find.text('Cancelled'), findsOneWidget);
    });

    testWidgets('Issue 226: completed occurrence shows Completed label', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        occurrence: _occurrence(status: OccurrenceStatus.completed),
      );
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets(
      'Issue 226: rescheduled with shifted start shows Rescheduled prefix',
      (tester) async {
        final original = _futureUtc(const Duration(hours: 6));
        final actual = _futureUtc(const Duration(hours: 6, minutes: 30));
        await _pumpCard(
          tester,
          occurrence: _occurrence(
            status: OccurrenceStatus.rescheduled,
            actualStart: actual,
            actualEnd: _futureUtc(const Duration(hours: 7, minutes: 30)),
            originalStart: original,
          ),
        );
        expect(find.textContaining('Rescheduled —'), findsOneWidget);
      },
    );
  });

  group('Issue 415: My Calendar past session cards', () {
    Occurrence past({AttendanceStatus? status}) {
      final start = DateTime.now().toUtc().subtract(const Duration(hours: 3));
      return _occurrence(
        status: OccurrenceStatus.scheduled,
        attendanceStatus: status,
        actualStart: start,
        actualEnd: start.add(const Duration(hours: 1)),
        originalStart: start,
      );
    }

    testWidgets(
      'Issue 415: a past session of an event the member is not enrolled in '
      'reads "You are not enrolled"',
      (tester) async {
        await _pumpCard(tester, occurrence: past());
        expect(find.text('You are not enrolled'), findsOneWidget);
        expect(find.text('Attendance not recorded'), findsNothing);
      },
    );

    testWidgets(
      'Issue 415: an enrolled member with no status still reads '
      '"Attendance not recorded"',
      (tester) async {
        await _pumpCard(tester, occurrence: past(), enrollment: _enrollment());
        expect(find.text('Attendance not recorded'), findsOneWidget);
        expect(find.text('You are not enrolled'), findsNothing);
      },
    );

    const expected = {
      AttendanceStatus.present: ('P', Colors.green),
      AttendanceStatus.absent: ('A', Colors.red),
      AttendanceStatus.late: ('L', Colors.orange),
      AttendanceStatus.onLeave: ('OL', Colors.blue),
      AttendanceStatus.onLeaveRequested: ('LR', Colors.amber),
    };
    for (final MapEntry(key: status, value: (code, color))
        in expected.entries) {
      testWidgets(
        'Issue 415: a past ${status.name} session shows the badge "$code" '
        'alone, in the staff colour',
        (tester) async {
          await _pumpCard(
            tester,
            occurrence: past(status: status),
            enrollment: _enrollment(),
          );
          final badge = find.byType(AttendanceBadge);
          expect(badge, findsOneWidget);
          final codeText = tester.widget<Text>(
            find.descendant(of: badge, matching: find.text(code)),
          );
          expect(codeText.style?.color, color);
          expect(tester.widget<AttendanceBadge>(badge).color, color);
          for (final caption in const [
            'You attended',
            'You were absent',
            'You were late',
            'You were on leave',
            'Leave was pending',
            'Attendance not recorded',
            'You are not enrolled',
          ]) {
            expect(find.text(caption), findsNothing, reason: caption);
          }
        },
      );
    }
  });

  group(
    'Issue 340: member-lens never falls back to clEventsMasterProvider',
    () {
      testWidgets(
        'Issue 340: missing event renders placeholder title without watching '
        'the admin events master',
        (tester) async {
          _SentinelEventsMasterNotifier.buildCalls = 0;
          final occurrence = _occurrence(status: OccurrenceStatus.scheduled);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                clMyEventsMasterProvider.overrideWith(
                  _EmptyMyEventsNotifier.new,
                ),
                clEventsMasterProvider.overrideWith(
                  _SentinelEventsMasterNotifier.new,
                ),
                authStateProvider.overrideWith(_NoAuthNotifier.new),
                clMyOccurrencesListProvider((
                  username: _username,
                  fromTimeUtc: _range.from,
                  toTimeUtc: _range.to,
                )).overrideWith((ref) async => [occurrence]),
                clMyEnrollmentProvider(
                  (username: _username, eventId: _eventId),
                ).overrideWith((ref) async => null),
              ],
              child: ShadApp(
                home: Scaffold(
                  body: SizedBox(
                    width: 800,
                    child: OccurrenceCard(
                      eventId: _eventId,
                      occurrenceTime: occurrence.originalStartTimeUtc,
                      range: _range,
                      username: _username,
                      onTap: () {},
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump();
          await tester.pump();

          expect(find.text('Event #$_eventId'), findsOneWidget);
          expect(tester.takeException(), isNull);
          expect(
            _SentinelEventsMasterNotifier.buildCalls,
            0,
            reason:
                'OccurrenceCard must not watch the admin events master in '
                'the member lens; #340 regression.',
          );
        },
      );
    },
  );
}
