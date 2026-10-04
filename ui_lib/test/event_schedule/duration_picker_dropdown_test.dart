import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/event_schedule/duration_picker_column.dart';
import 'package:ui_lib/src/widgets/event_schedule/duration_picker_dropdown.dart';

Future<void> _pumpDropdown(
  WidgetTester tester, {
  required Duration value,
  required ValueChanged<Duration> onChanged,
  Duration min = const Duration(minutes: 15),
  Duration max = const Duration(hours: 8),
  bool enabled = true,
}) async {
  tester.view.physicalSize = const Size(800, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 200,
            child: DurationPickerDropdown(
              value: value,
              min: min,
              max: max,
              enabled: enabled,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('DurationPickerDropdown', () {
    testWidgets('the trigger renders the value as H:MM', (tester) async {
      await _pumpDropdown(
        tester,
        value: const Duration(hours: 1, minutes: 30),
        onChanged: (_) {},
      );
      expect(find.text('1:30'), findsOneWidget);
    });

    testWidgets('tapping the trigger opens the popover', (tester) async {
      await _pumpDropdown(
        tester,
        value: const Duration(hours: 1),
        onChanged: (_) {},
      );
      // Popover columns are not in the tree until the trigger is tapped.
      expect(find.byType(DurationPickerColumn), findsNothing);

      await tester.tap(find.text('1:00'));
      await tester.pumpAndSettle();
      expect(find.byType(DurationPickerColumn), findsNWidgets(2));
      expect(find.text('Hours'), findsOneWidget);
      expect(find.text('Minutes'), findsOneWidget);
    });

    testWidgets('with max=0:30 hour=0 the minute column omits 45', (
      tester,
    ) async {
      // Default min=0:15 — so for hour=0 the options are [15, 30] only;
      // 00 falls below the min and 45 above the max.
      await _pumpDropdown(
        tester,
        value: const Duration(minutes: 15),
        max: const Duration(minutes: 30),
        onChanged: (_) {},
      );
      await tester.tap(find.text('0:15'));
      await tester.pumpAndSettle();
      expect(find.text('0'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('45'), findsNothing);
    });

    testWidgets('with min=0 hour=0 the minute column shows 00 too', (
      tester,
    ) async {
      await _pumpDropdown(
        tester,
        value: const Duration(minutes: 15),
        min: Duration.zero,
        max: const Duration(minutes: 30),
        onChanged: (_) {},
      );
      await tester.tap(find.text('0:15'));
      await tester.pumpAndSettle();
      expect(find.text('00'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('45'), findsNothing);
    });

    testWidgets('picking a minute closes the popover and emits the duration', (
      tester,
    ) async {
      Duration? picked;
      await _pumpDropdown(
        tester,
        value: const Duration(hours: 1),
        onChanged: (d) => picked = d,
      );
      await tester.tap(find.text('1:00'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('30'));
      await tester.pumpAndSettle();

      expect(picked, const Duration(hours: 1, minutes: 30));
      // Popover dismisses after a minute pick.
      expect(find.byType(DurationPickerColumn), findsNothing);
    });

    testWidgets('disabled trigger does not open the popover', (tester) async {
      await _pumpDropdown(
        tester,
        value: const Duration(hours: 1),
        enabled: false,
        onChanged: (_) {},
      );
      await tester.tap(find.text('1:00'));
      await tester.pumpAndSettle();
      expect(find.byType(DurationPickerColumn), findsNothing);
    });
  });
}
