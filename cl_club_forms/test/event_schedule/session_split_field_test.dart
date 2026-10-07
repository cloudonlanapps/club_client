// SessionSplitField is a cluster, not a form: it has no validator, no rule
// across fields and no `validate()` / `isDirty` / `showErrors` of its own.
// Those are tested on the fields and forms that host it.
import 'package:cl_club_forms/src/models/session_input.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/duration_picker_column.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/session_split_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/form_harness.dart';
import '../support/programme_timetable_support.dart';

const List<SessionInput> _threeParts = [
  SessionInput(name: 'A', startTime: '06:00', endTime: '06:30'),
  SessionInput(name: 'B', startTime: '06:30', endTime: '07:00'),
  SessionInput(name: 'C', startTime: '07:00', endTime: '08:00'),
];

/// Mounts the editor alone and returns what it emits, oldest first.
Future<List<List<SessionInput>>> _pump(
  WidgetTester tester, {
  int totalMinutes = 120,
  ShadTimeOfDay? startTime = kSixAm,
  List<SessionInput> initialSessions = const [],
  bool enabled = true,
  Size size = kFormSurface,
  List<List<SessionInput>>? emitted,
}) async {
  final log = emitted ?? <List<SessionInput>>[];
  await pumpForm(
    tester,
    SessionSplitField(
      totalMinutes: totalMinutes,
      startTime: startTime,
      initialSessions: initialSessions,
      enabled: enabled,
      onChanged: log.add,
    ),
    size: size,
  );
  return log;
}

List<String> _names(WidgetTester tester) => [
  for (final input in tester.widgetList<ShadInput>(find.byType(ShadInput)))
    input.controller!.text,
];

void main() {
  group('Issue 61: SessionSplitField helpers', () {
    test('Issue 61: formatDuration writes whole hours, minutes and both', () {
      expect(SessionSplitField.formatDuration(60), '1h');
      expect(SessionSplitField.formatDuration(240), '4h');
      expect(SessionSplitField.formatDuration(45), '45m');
      expect(SessionSplitField.formatDuration(90), '1h 30m');
      expect(SessionSplitField.formatDuration(75), '1h 15m');
    });

    test('Issue 61: parseStandardHM reads only 24-hour times', () {
      expect(SessionSplitField.parseStandardHM('00:00'), 0);
      expect(SessionSplitField.parseStandardHM(' 23:59 '), 23 * 60 + 59);
      expect(SessionSplitField.parseStandardHM('06:30:00'), 390);
      expect(SessionSplitField.parseStandardHM('24:00'), isNull);
      expect(SessionSplitField.parseStandardHM('06:60'), isNull);
      expect(SessionSplitField.parseStandardHM('6:00 AM'), isNull);
      expect(SessionSplitField.parseStandardHM('06'), isNull);
      expect(SessionSplitField.parseStandardHM('06:00:00:00'), isNull);
    });

    test('Issue 61: parseTwelveHourHM reads only AM/PM times', () {
      expect(SessionSplitField.parseTwelveHourHM('12:00 AM'), 0);
      expect(SessionSplitField.parseTwelveHourHM('12:30 pm'), 12 * 60 + 30);
      expect(SessionSplitField.parseTwelveHourHM('1:05 PM'), 13 * 60 + 5);
      expect(SessionSplitField.parseTwelveHourHM('11:59PM'), 23 * 60 + 59);
      expect(SessionSplitField.parseTwelveHourHM('13:05'), isNull);
      expect(SessionSplitField.parseTwelveHourHM('x:05 PM'), isNull);
      expect(SessionSplitField.parseTwelveHourHM('6 AM'), isNull);
    });

    test('Issue 61: formatHM and sessionMinutes agree on a session', () {
      expect(SessionSplitField.formatHM(0), '00:00');
      expect(SessionSplitField.formatHM(6 * 60 + 5), '06:05');
      expect(
        SessionSplitField.sessionMinutes(kWarmUpAndDrills.last),
        90,
      );
      expect(
        SessionSplitField.sessionMinutes(
          const SessionInput(name: 'x', startTime: '', endTime: '07:00'),
        ),
        0,
      );
    });

    test('Issue 61: walkedFrom keeps names and lengths from a new start', () {
      expect(
        SessionSplitField.walkedFrom(
          kWarmUpAndDrills,
          const ShadTimeOfDay(hour: 17, minute: 15, second: 0),
        ),
        const [
          SessionInput(name: 'Warm-up', startTime: '17:15', endTime: '17:45'),
          SessionInput(name: 'Drills', startTime: '17:45', endTime: '19:15'),
        ],
      );
      expect(SessionSplitField.walkedFrom(const [], kSixAm), isEmpty);
    });
  });

  group('Issue 61: SessionSplitField', () {
    testWidgets('Issue 61: an undivided day is one unnamed row of the whole '
        'length, with nothing to remove', (tester) async {
      final emitted = await _pump(tester);

      expect(_names(tester), ['']);
      expect(find.text('Session 1'), findsOneWidget, reason: 'placeholder');
      expect(shownDurations(tester), ['2:00']);
      expect(find.byType(IconButton), findsNothing);
      expect(find.textContaining('unassigned'), findsNothing);
      expect(emitted, isEmpty, reason: 'mounting emits nothing');
    });

    testWidgets('Issue 61: a seeded split shows one named row per session, '
        'each removable', (tester) async {
      final emitted = await _pump(tester, initialSessions: _threeParts);

      expect(_names(tester), ['A', 'B', 'C']);
      expect(shownDurations(tester), ['0:30', '0:30', '1:00']);
      expect(find.byType(IconButton), findsNWidgets(3));
      expect(emitted, isEmpty);
    });

    testWidgets('Issue 61: shortening the only row adds a row holding the '
        'rest and emits both, named by position', (tester) async {
      final emitted = await _pump(tester);

      await pickHour(tester, 0, 1);

      expect(shownDurations(tester), ['1:00', '1:00']);
      expect(emitted.last, const [
        SessionInput(name: 'Session 1', startTime: '06:00', endTime: '07:00'),
        SessionInput(name: 'Session 2', startTime: '07:00', endTime: '08:00'),
      ]);
    });

    testWidgets('Issue 61: shortening a middle row gives the minutes to the '
        'row after it', (tester) async {
      final emitted = await _pump(
        tester,
        totalMinutes: 180,
        initialSessions: const [
          SessionInput(name: 'A', startTime: '06:00', endTime: '06:30'),
          SessionInput(name: 'B', startTime: '06:30', endTime: '08:00'),
          SessionInput(name: 'C', startTime: '08:00', endTime: '09:00'),
        ],
      );

      // B: 1:30 -> 0:30 (hour 0 keeps its 30 minutes).
      await pickHour(tester, 1, 0);

      expect(shownDurations(tester), ['0:30', '0:30', '2:00']);
      expect(emitted.last.map((s) => '${s.name} ${s.startTime}-${s.endTime}'), [
        'A 06:00-06:30',
        'B 06:30-07:00',
        'C 07:00-09:00',
      ]);
    });

    testWidgets('Issue 61: lengthening a row takes the minutes from the last '
        'rows, dropping one it uses up', (tester) async {
      final emitted = await _pump(tester, initialSessions: _threeParts);

      // A: 0:30 -> 1:30 uses up the whole of C (1:00).
      await pickHour(tester, 0, 1);

      expect(_names(tester), ['A', 'B']);
      expect(shownDurations(tester), ['1:30', '0:30']);
      expect(emitted.last, const [
        SessionInput(name: 'A', startTime: '06:00', endTime: '07:30'),
        SessionInput(name: 'B', startTime: '07:30', endTime: '08:00'),
      ]);
    });

    testWidgets('Issue 61: a row cannot be made longer than what is left '
        'after the rows before it', (tester) async {
      await _pump(tester, initialSessions: _threeParts);

      // B starts 30 minutes in, so of the two hours 1:30 is left: the hours
      // column offers 0 and 1 only.
      await tester.tap(find.text('0:30').last);
      await tester.pumpAndSettle();
      final hours = tester.widget<DurationPickerColumn>(
        find.byType(DurationPickerColumn).first,
      );
      expect(hours.options, [0, 1]);
    });

    testWidgets('Issue 61: a typed name is emitted trimmed, and a blank one '
        'falls back to its position', (tester) async {
      final emitted = await _pump(tester, initialSessions: kWarmUpAndDrills);

      await tester.enterText(find.byType(EditableText).first, '  Off-ice  ');
      await tester.pumpAndSettle();
      expect(emitted.last.map((s) => s.name), ['Off-ice', 'Drills']);

      await tester.enterText(find.byType(EditableText).last, '   ');
      await tester.pumpAndSettle();
      expect(emitted.last.map((s) => s.name), ['Off-ice', 'Session 2']);
      expect(emitted.last.last.endTime, '08:00', reason: 'lengths kept');
    });

    testWidgets('Issue 61: removing a row gives its minutes to the last row', (
      tester,
    ) async {
      final emitted = await _pump(tester, initialSessions: _threeParts);

      await tester.tap(find.byType(IconButton).at(1));
      await tester.pumpAndSettle();

      expect(_names(tester), ['A', 'C']);
      expect(shownDurations(tester), ['0:30', '1:30']);
      expect(emitted.last, const [
        SessionInput(name: 'A', startTime: '06:00', endTime: '06:30'),
        SessionInput(name: 'C', startTime: '06:30', endTime: '08:00'),
      ]);
    });

    testWidgets('Issue 61: removing down to one row emits no split', (
      tester,
    ) async {
      final emitted = await _pump(tester, initialSessions: kWarmUpAndDrills);

      await tester.tap(find.byType(IconButton).first);
      await tester.pumpAndSettle();

      expect(shownDurations(tester), ['2:00']);
      expect(find.byType(IconButton), findsNothing);
      expect(emitted, [isEmpty]);
    });

    testWidgets('Issue 61: sessions shorter than the day show what is '
        'unassigned', (tester) async {
      await _pump(tester, totalMinutes: 150, initialSessions: _threeParts);
      expect(find.text('30m unassigned.'), findsOneWidget);
    });

    testWidgets('Issue 61: a new total resets the editor to one row without '
        'emitting', (tester) async {
      final emitted = await _pump(tester, initialSessions: _threeParts);

      await _pump(
        tester,
        totalMinutes: 90,
        initialSessions: _threeParts,
        emitted: emitted,
      );

      expect(_names(tester), ['']);
      expect(shownDurations(tester), ['1:30']);
      expect(emitted, isEmpty);
    });

    testWidgets('Issue 61: without a start time no split is emitted', (
      tester,
    ) async {
      final emitted = await _pump(tester, startTime: null);

      await pickHour(tester, 0, 1);

      expect(shownDurations(tester), ['1:00', '1:00']);
      expect(emitted, [isEmpty]);
    });

    testWidgets('Issue 61: disabled, no name, length or remove button '
        'responds', (tester) async {
      final emitted = await _pump(
        tester,
        initialSessions: _threeParts,
        enabled: false,
      );

      for (final input in tester.widgetList<ShadInput>(
        find.byType(ShadInput),
      )) {
        expect(input.enabled, isFalse);
      }
      for (final button in tester.widgetList<IconButton>(
        find.byType(IconButton),
      )) {
        expect(button.onPressed, isNull);
      }
      await tester.tap(find.text('1:00'));
      await tester.pumpAndSettle();
      expect(find.byType(DurationPickerColumn), findsNothing);
      await tester.tap(find.byType(IconButton).first, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(_names(tester), ['A', 'B', 'C']);
      expect(emitted, isEmpty);
    });

    testWidgets('Issue 61: a split fits a phone', (tester) async {
      await _pump(tester, initialSessions: _threeParts, size: kPhoneSurface);
      expect(tester.takeException(), isNull);
      expect(_names(tester), ['A', 'B', 'C']);
    });
  });
}
