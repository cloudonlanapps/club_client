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

Future<void> _pumpCard(
  WidgetTester tester, {
  required Occurrence occurrence,
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

  group('Issue 543: My Calendar caption reads occurrence.attendanceStatus', () {
    testWidgets(
      'Issue 543: past occurrence with attendanceStatus.present shows the '
      'recorded status caption',
      (tester) async {
        final originalStart = DateTime.now().toUtc().subtract(
          const Duration(hours: 3),
        );
        final actualEnd = DateTime.now().toUtc().subtract(
          const Duration(hours: 2),
        );
        await _pumpCard(
          tester,
          occurrence: _occurrence(
            status: OccurrenceStatus.scheduled,
            attendanceStatus: AttendanceStatus.present,
            actualStart: originalStart,
            actualEnd: actualEnd,
            originalStart: originalStart,
          ),
        );
        expect(find.text('You attended'), findsOneWidget);
        expect(find.text('Attendance not recorded'), findsNothing);
      },
    );

    testWidgets(
      'Issue 543: past occurrence with null attendanceStatus shows '
      '"Attendance not recorded"',
      (tester) async {
        final originalStart = DateTime.now().toUtc().subtract(
          const Duration(hours: 3),
        );
        final actualEnd = DateTime.now().toUtc().subtract(
          const Duration(hours: 2),
        );
        await _pumpCard(
          tester,
          occurrence: _occurrence(
            status: OccurrenceStatus.scheduled,
            actualStart: originalStart,
            actualEnd: actualEnd,
            originalStart: originalStart,
          ),
        );
        expect(find.text('Attendance not recorded'), findsOneWidget);
      },
    );
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
