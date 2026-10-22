import 'package:cl_club_events/src/models/schedule_clash_gate.dart';
import 'package:cl_club_events/src/utils/schedule_clash_window.dart';
import 'package:cl_club_events/src/widgets/schedule_clash/schedule_clash_dialog.dart';
import 'package:cl_club_events/src/widgets/schedule_clash/schedule_clash_item.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/schedule_clash_fixtures.dart';

/// Pumps a button that opens the dialog for [report] and records what it
/// returns in the list it gives back.
Future<List<bool>> _pumpOpener(
  WidgetTester tester,
  ConflictReport report,
) async {
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final results = <bool>[];
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ShadButton(
            onPressed: () async => results.add(
              await ScheduleClashDialog.show(context, report: report),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return results;
}

final DateTime _start = DateTime.utc(2030, 6, 1, 17);
final DateTime _end = DateTime.utc(2030, 6, 1, 18, 30);

ConflictReport _everyGate() => scheduleClash(
  venue: [
    clashingEvent('Summer camp', type: 'camp', windows: [(_start, _end)]),
  ],
  organizer: [
    clashingEvent('Open day', type: 'oneOff', windows: [(_start, _end)]),
  ],
  coach: [
    clashingEvent('Evening squad', windows: [(_start, _end)]),
  ],
).report;

void main() {
  group('Issue 278: the schedule clash dialog', () {
    testWidgets('Issue 278: lists each clash under venue, organizer and '
        'coach, in that order', (tester) async {
      await _pumpOpener(tester, _everyGate());

      expect(find.text(ScheduleClashDialog.title), findsOneWidget);
      final venue = tester.getTopLeft(find.text(ScheduleClashGate.venue.label));
      final organizer = tester.getTopLeft(
        find.text(ScheduleClashGate.organizer.label),
      );
      final coach = tester.getTopLeft(find.text(ScheduleClashGate.coach.label));
      expect(venue.dy, lessThan(organizer.dy));
      expect(organizer.dy, lessThan(coach.dy));

      // Each clashing event sits under its own gate, with its type.
      final camp = tester.getTopLeft(find.text('Summer camp · Camp'));
      final openDay = tester.getTopLeft(find.text('Open day · One-off'));
      final squad = tester.getTopLeft(find.text('Evening squad · Programme'));
      expect(camp.dy, inExclusiveRange(venue.dy, organizer.dy));
      expect(openDay.dy, inExclusiveRange(organizer.dy, coach.dy));
      expect(squad.dy, greaterThan(coach.dy));
    });

    testWidgets('Issue 278: shows the clashing dates and times', (
      tester,
    ) async {
      await _pumpOpener(tester, _everyGate());

      expect(
        find.text(scheduleClashWindowLabel(_start, _end)),
        findsNWidgets(3),
      );
    });

    testWidgets('Issue 278: a coach-only clash shows the coach group alone', (
      tester,
    ) async {
      await _pumpOpener(tester, coachOnlyClash().report);

      expect(find.text(ScheduleClashGate.coach.label), findsOneWidget);
      expect(find.text(ScheduleClashGate.venue.label), findsNothing);
      expect(find.text(ScheduleClashGate.organizer.label), findsNothing);
      expect(find.text('Evening squad · Programme'), findsOneWidget);
    });

    testWidgets('Issue 278: many overlapping sessions are counted after the '
        'first few', (tester) async {
      final windows = [
        for (var day = 1; day <= 8; day++)
          (DateTime.utc(2030, 6, day, 17), DateTime.utc(2030, 6, day, 18)),
      ];
      await _pumpOpener(
        tester,
        scheduleClash(
          venue: [clashingEvent('Long league', windows: windows)],
        ).report,
      );

      for (final (start, end) in windows.take(
        ScheduleClashItem.maxListedWindows,
      )) {
        expect(find.text(scheduleClashWindowLabel(start, end)), findsOneWidget);
      }
      expect(
        find.text(scheduleClashWindowLabel(windows.last.$1, windows.last.$2)),
        findsNothing,
      );
      expect(
        find.text(
          ScheduleClashItem.moreWindows(
            windows.length - ScheduleClashItem.maxListedWindows,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Issue 278: Save anyway answers true', (tester) async {
      final results = await _pumpOpener(tester, _everyGate());

      await saveAnyway(tester);

      expect(results, [true]);
      expect(clashDialog, findsNothing);
    });

    testWidgets('Issue 278: Cancel answers false', (tester) async {
      final results = await _pumpOpener(tester, _everyGate());

      await cancelClash(tester);

      expect(results, [false]);
      expect(clashDialog, findsNothing);
    });
  });

  group('Issue 278: scheduleClashWindowLabel', () {
    test('Issue 278: a window on one day names the day once', () {
      final start = DateTime(2030, 6, 1, 18);
      final end = DateTime(2030, 6, 1, 19, 30);

      expect(
        scheduleClashWindowLabel(start.toUtc(), end.toUtc()),
        'Sat 1 Jun 2030, 6:00 PM – 7:30 PM',
      );
    });

    test('Issue 278: a window past midnight names both days', () {
      final start = DateTime(2030, 6, 1, 23);
      final end = DateTime(2030, 6, 2, 1);

      expect(
        scheduleClashWindowLabel(start.toUtc(), end.toUtc()),
        'Sat 1 Jun 2030, 11:00 PM – Sun 2 Jun 2030, 1:00 AM',
      );
    });
  });
}
