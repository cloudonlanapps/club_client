import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/event_schedule/weekday_selector.dart';

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
  });
}
