import 'package:cl_calendar/cl_calendar.dart';
import 'package:cl_club_events/src/models/my_range_occurrences_key.dart';
import 'package:cl_club_events/src/providers/day_event_counts.dart';
import 'package:cl_club_events/src/providers/my_day_attendance.dart';
import 'package:cl_club_events/src/providers/my_day_event_counts.dart';
import 'package:cl_club_events/src/widgets/attendance_pie.dart';
import 'package:cl_club_events/src/widgets/calendar_day_view.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show FilmRollColorsExtension, darkCustomColors, lightCustomColors;

const _member = 'member416';
final MonthViewRange _range = MonthViewRange(year: 2026, month: 11);
final DateTime _day = DateTime(2026, 11, 5);

Occurrence _session(
  int eventId,
  DateTime startLocal, {
  AttendanceStatus? status,
}) => Occurrence(
  eventId: eventId,
  originalStartTimeUtc: startLocal.toUtc(),
  actualStartTimeUtc: startLocal.toUtc(),
  actualEndTimeUtc: startLocal.toUtc().add(const Duration(hours: 1)),
  status: OccurrenceStatus.scheduled,
  venueId: 1,
  attendanceStatus: status,
);

ShadThemeData _theme(Brightness brightness) => ShadThemeData(
  brightness: brightness,
  colorScheme: brightness == Brightness.dark
      ? const ShadSlateColorScheme.dark().copyWith(custom: darkCustomColors)
      : const ShadSlateColorScheme.light().copyWith(custom: lightCustomColors),
);

/// Pumps the member's month-view cell for [_day], [size] big, whose day
/// holds [statuses] (none: nothing recorded). [special] highlights the day
/// as a camp's; [selected] selects it; [member] false pumps the staff cell.
Future<void> _pumpCell(
  WidgetTester tester, {
  List<AttendanceStatus>? statuses,
  Size size = const Size(60, 48),
  bool selected = false,
  bool special = false,
  bool member = true,
  Brightness brightness = Brightness.light,
}) async {
  final counts = <DateTime, ({int programme, int oneoff, int camp})>{
    _day: (programme: 1, oneoff: 0, camp: special ? 1 : 0),
  };
  // A fresh scope each time: a scope kept across pumps keeps its old
  // overrides' values.
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        myDayEventCountsProvider.overrideWith((ref, key) async => counts),
        dayEventCountsProvider.overrideWith((ref, key) async => counts),
        myDayAttendanceProvider.overrideWith(
          (ref, key) async => statuses == null ? {} : {_day: statuses},
        ),
      ],
      child: ShadApp(
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        home: Scaffold(
          body: Center(
            child: CalendarDayView(
              date: _day,
              size: size,
              range: _range,
              selectedDateTime: selected ? _day : DateTime(2026, 11, 20),
              onChangeSelectedDateTime: (_) {},
              memberUsername: member ? _member : null,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

AttendancePie _pie(WidgetTester tester) =>
    tester.widget<AttendancePie>(find.byType(AttendancePie));

/// The cell's own background colour.
Color? _cellColor(WidgetTester tester) {
  final box = tester.widget<Container>(
    find.ancestor(of: find.text('5'), matching: find.byType(Container)).first,
  );
  return (box.decoration as BoxDecoration?)?.color;
}

void main() {
  group('Issue 416: the member month view shows a pie of the day', () {
    testWidgets('Issue 416: a day of one session is a full circle', (
      tester,
    ) async {
      await _pumpCell(tester, statuses: [AttendanceStatus.present]);

      expect(find.byType(AttendancePie), findsOneWidget);
      expect(_pie(tester).sliceColors, [Colors.green]);
    });

    testWidgets(
      'Issue 416: a mixed day has one slice per session in the staff colours',
      (tester) async {
        await _pumpCell(
          tester,
          statuses: const [
            AttendanceStatus.present,
            AttendanceStatus.absent,
            AttendanceStatus.late,
            AttendanceStatus.onLeave,
            AttendanceStatus.onLeaveRequested,
          ],
        );

        expect(_pie(tester).sliceColors, [
          Colors.green,
          Colors.red,
          Colors.orange,
          Colors.blue,
          Colors.amber,
        ]);
      },
    );

    testWidgets('Issue 416: a day with nothing recorded shows no pie', (
      tester,
    ) async {
      await _pumpCell(tester);

      expect(find.text('5'), findsOneWidget);
      expect(find.byType(AttendancePie), findsNothing);
    });

    testWidgets('Issue 416: the staff month view shows no pie', (
      tester,
    ) async {
      await _pumpCell(
        tester,
        statuses: [AttendanceStatus.present],
        member: false,
      );

      expect(find.byType(AttendancePie), findsNothing);
    });

    testWidgets(
      'Issue 416: the pie scales with the cell, in its bottom-right corner, '
      'and the date stays centred',
      (tester) async {
        for (final size in const [Size(40, 32), Size(120, 96)]) {
          await _pumpCell(
            tester,
            statuses: [AttendanceStatus.late],
            size: size,
          );
          final cell = tester.getRect(find.byType(CalendarDayView));
          final pie = tester.getRect(find.byType(AttendancePie));
          expect(pie.height, closeTo(size.height / 4, 0.01));
          expect(pie.right, lessThan(cell.right));
          expect(pie.bottom, lessThan(cell.bottom));
          expect(pie.center.dx, greaterThan(cell.center.dx));
          expect(pie.center.dy, greaterThan(cell.center.dy));
          expect(
            tester.getCenter(find.text('5')),
            offsetMoreOrLessEquals(cell.center, epsilon: 0.5),
          );
        }
      },
    );

    testWidgets(
      'Issue 416: on a wide, short cell the pie takes a tenth of the width, '
      'at most 45% of the height',
      (tester) async {
        for (final (size, expected) in const [
          (Size(161, 37), 16.1),
          (Size(400, 37), 16.65),
        ]) {
          await _pumpCell(
            tester,
            statuses: [AttendanceStatus.present],
            size: size,
          );
          final pie = tester.getRect(find.byType(AttendancePie));
          expect(pie.height, closeTo(expected, 0.01), reason: '$size');
        }
      },
    );

    for (final brightness in Brightness.values) {
      testWidgets(
        'Issue 416: on the selected day and a highlighted day, '
        '${brightness.name}, the pie is ringed in the cell colour',
        (tester) async {
          await _pumpCell(
            tester,
            statuses: const [
              AttendanceStatus.late,
              AttendanceStatus.onLeaveRequested,
            ],
            selected: true,
            brightness: brightness,
          );
          final selectedColor = _cellColor(tester);
          expect(selectedColor, _theme(brightness).colorScheme.selection);
          expect(_pie(tester).outlineColor, selectedColor);

          await _pumpCell(
            tester,
            statuses: const [
              AttendanceStatus.late,
              AttendanceStatus.onLeaveRequested,
            ],
            special: true,
            brightness: brightness,
          );
          final highlight = _cellColor(tester);
          expect(
            highlight,
            _theme(brightness).colorScheme.specialEventHighlight,
          );
          expect(_pie(tester).outlineColor, highlight);
          expect(_pie(tester).sliceColors, [Colors.orange, Colors.amber]);
        },
      );
    }
  });

  test(
    'Issue 416: the day attendance groups recorded sessions by local day, '
    'in start order, leaving unmarked ones out',
    () async {
      final container = ProviderContainer(
        overrides: [
          clMyOccurrencesProvider.overrideWith(
            (ref, key) async => [
              _session(
                2,
                DateTime(2026, 11, 5, 18),
                status: AttendanceStatus.late,
              ),
              _session(
                1,
                DateTime(2026, 11, 5, 5),
                status: AttendanceStatus.present,
              ),
              _session(3, DateTime(2026, 11, 5, 20)),
              _session(1, DateTime(2026, 11, 6, 5)),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);
      final MyRangeOccurrencesKey key = (username: _member, range: _range);

      final days = await container.read(myDayAttendanceProvider(key).future);

      expect(days, {
        _day: [AttendanceStatus.present, AttendanceStatus.late],
      });
    },
  );
}
