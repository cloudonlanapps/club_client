import 'package:cl_club_forms/src/widgets/event_schedule/weekday_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Future<Set<int>> _pumpAndCaptureSelection(
  WidgetTester tester, {
  Set<int> initial = const {},
  bool enabled = true,
}) async {
  var captured = <int>{};
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: WeekdaySelector(
          selectedDays: initial,
          enabled: enabled,
          onChanged: (days) => captured = days,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return captured;
}

void main() {
  group('WeekdaySelector', () {
    testWidgets('renders 7 chips with single-letter labels M T W T F S S', (
      tester,
    ) async {
      await _pumpAndCaptureSelection(tester);
      // The 'T' and 'S' letters appear twice; just assert each chip
      // widget exists.
      expect(find.byType(WeekdayChip), findsNWidgets(7));
      // Each chip's letter should match weekdayInitials.
      for (var i = 0; i < 7; i++) {
        final chip = tester.widget<WeekdayChip>(find.byType(WeekdayChip).at(i));
        expect(chip.letter, weekdayInitials[i]);
      }
    });

    testWidgets('tapping a chip emits the toggled day', (tester) async {
      Set<int>? captured;
      await tester.pumpWidget(
        ShadApp(
          home: Scaffold(
            body: WeekdaySelector(
              selectedDays: const {},
              onChanged: (days) => captured = days,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(WeekdayChip).first);
      await tester.pumpAndSettle();
      expect(captured, {1});
    });

    testWidgets('tapping a selected chip removes it from the set', (
      tester,
    ) async {
      Set<int>? captured;
      await tester.pumpWidget(
        ShadApp(
          home: Scaffold(
            body: WeekdaySelector(
              selectedDays: const {1, 3},
              onChanged: (days) => captured = days,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(WeekdayChip).first);
      await tester.pumpAndSettle();
      expect(captured, {3});
    });

    testWidgets('tapping a chip when disabled is a no-op', (tester) async {
      var fired = false;
      await tester.pumpWidget(
        ShadApp(
          home: Scaffold(
            body: WeekdaySelector(
              selectedDays: const {},
              enabled: false,
              onChanged: (_) => fired = true,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(WeekdayChip).first);
      await tester.pumpAndSettle();
      expect(fired, isFalse);
    });

    testWidgets('Issue 61: the chips of the selected days, and only those, '
        'are marked selected', (tester) async {
      await _pumpAndCaptureSelection(tester, initial: {2, 7});

      final chips = tester
          .widgetList<WeekdayChip>(find.byType(WeekdayChip))
          .toList();
      expect(
        [for (final chip in chips) chip.selected],
        [
          false,
          true,
          false,
          false,
          false,
          false,
          true,
        ],
      );
    });

    testWidgets('Issue 61: each chip names its day in full, Monday first', (
      tester,
    ) async {
      await _pumpAndCaptureSelection(tester);

      expect(
        [
          for (final chip in tester.widgetList<WeekdayChip>(
            find.byType(WeekdayChip),
          ))
            chip.tooltip,
        ],
        [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ],
      );
      expect(find.byTooltip('Sunday'), findsOneWidget);
    });

    testWidgets('Issue 61: the last chip is day 7, Sunday', (tester) async {
      Set<int>? captured;
      await tester.pumpWidget(
        ShadApp(
          home: Scaffold(
            body: WeekdaySelector(
              selectedDays: const {1},
              onChanged: (days) => captured = days,
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Sunday'));
      await tester.pumpAndSettle();
      expect(captured, {1, 7});
    });

    testWidgets('Issue 61: a tap reports a new set and leaves the given one '
        'as it was', (tester) async {
      final given = {1, 3};
      Set<int>? captured;
      await tester.pumpWidget(
        ShadApp(
          home: Scaffold(
            body: WeekdaySelector(
              selectedDays: given,
              onChanged: (days) => captured = days,
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Wednesday'));
      await tester.pumpAndSettle();
      expect(captured, {1});
      expect(given, {1, 3});
    });

    testWidgets('Issue 61: a disabled selector still shows what is selected', (
      tester,
    ) async {
      var fired = false;
      await tester.pumpWidget(
        ShadApp(
          home: Scaffold(
            body: WeekdaySelector(
              selectedDays: const {4},
              enabled: false,
              onChanged: (_) => fired = true,
            ),
          ),
        ),
      );
      for (final day in ['Monday', 'Thursday']) {
        await tester.tap(find.byTooltip(day));
      }
      await tester.pumpAndSettle();
      expect(fired, isFalse);
      expect(
        tester.widget<WeekdayChip>(find.byType(WeekdayChip).at(3)).selected,
        isTrue,
      );
    });

    testWidgets('Issue 61: the seven chips fit a phone', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpAndCaptureSelection(tester, initial: {1, 2, 3, 4, 5, 6, 7});

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(WeekdaySelector)).width,
        lessThanOrEqualTo(390 - 32),
      );
    });
  });
}
