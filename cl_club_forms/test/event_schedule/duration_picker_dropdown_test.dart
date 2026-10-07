import 'package:cl_club_forms/src/widgets/event_schedule/duration_picker_column.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/duration_picker_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Future<void> _pumpDropdown(
  WidgetTester tester, {
  required Duration value,
  required ValueChanged<Duration> onChanged,
  Duration min = const Duration(minutes: 15),
  Duration max = const Duration(hours: 8),
  Duration step = const Duration(minutes: 15),
  Widget? placeholder,
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
              step: step,
              placeholder: placeholder,
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

    testWidgets('Issue 61: picking an hour keeps the minutes, emits and '
        'closes', (tester) async {
      Duration? picked;
      await _pumpDropdown(
        tester,
        value: const Duration(hours: 1, minutes: 30),
        onChanged: (d) => picked = d,
      );
      await tester.tap(find.text('1:30'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();

      expect(picked, const Duration(hours: 3, minutes: 30));
      expect(find.byType(DurationPickerColumn), findsNothing);
    });

    testWidgets('Issue 61: an hour that would pass the max emits the max', (
      tester,
    ) async {
      Duration? picked;
      await _pumpDropdown(
        tester,
        value: const Duration(minutes: 45),
        max: const Duration(hours: 2, minutes: 30),
        onChanged: (d) => picked = d,
      );
      await tester.tap(find.text('0:45'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();

      expect(picked, const Duration(hours: 2, minutes: 30));
    });

    testWidgets('Issue 61: hour 0 on a whole hour emits the min and stays '
        'open for the minutes', (tester) async {
      Duration? picked;
      await _pumpDropdown(
        tester,
        value: const Duration(hours: 1),
        onChanged: (d) => picked = d,
      );
      await tester.tap(find.text('1:00'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('0'));
      await tester.pumpAndSettle();

      expect(picked, const Duration(minutes: 15));
      expect(find.byType(DurationPickerColumn), findsNWidgets(2));
    });

    testWidgets('Issue 61: the hours column runs from 0 to the max hour', (
      tester,
    ) async {
      await _pumpDropdown(
        tester,
        value: const Duration(hours: 1),
        max: const Duration(hours: 3),
        onChanged: (_) {},
      );
      await tester.tap(find.text('1:00'));
      await tester.pumpAndSettle();

      final hours = tester.widget<DurationPickerColumn>(
        find.byType(DurationPickerColumn).first,
      );
      expect(hours.options, [0, 1, 2, 3]);
      expect(hours.selected, 1);
    });

    testWidgets('Issue 61: at the max hour only the minutes up to the max '
        'are offered', (tester) async {
      await _pumpDropdown(
        tester,
        value: const Duration(hours: 2),
        max: const Duration(hours: 2, minutes: 15),
        onChanged: (_) {},
      );
      await tester.tap(find.text('2:00'));
      await tester.pumpAndSettle();

      final minutes = tester.widget<DurationPickerColumn>(
        find.byType(DurationPickerColumn).last,
      );
      expect(minutes.options, [0, 15]);
    });

    testWidgets('Issue 61: the step sets the minutes offered', (tester) async {
      await _pumpDropdown(
        tester,
        value: const Duration(hours: 1),
        step: const Duration(minutes: 30),
        onChanged: (_) {},
      );
      await tester.tap(find.text('1:00'));
      await tester.pumpAndSettle();

      final minutes = tester.widget<DurationPickerColumn>(
        find.byType(DurationPickerColumn).last,
      );
      expect(minutes.options, [0, 30]);
    });

    testWidgets('Issue 61: a value outside the bounds shows as the nearest '
        'bound', (tester) async {
      await _pumpDropdown(
        tester,
        value: const Duration(hours: 9),
        max: const Duration(hours: 2),
        onChanged: (_) {},
      );
      expect(find.text('2:00'), findsOneWidget);

      await _pumpDropdown(
        tester,
        value: Duration.zero,
        onChanged: (_) {},
      );
      expect(find.text('0:15'), findsOneWidget);
    });

    testWidgets('Issue 61: at zero with a placeholder the trigger shows no '
        'duration', (tester) async {
      await _pumpDropdown(
        tester,
        value: Duration.zero,
        min: Duration.zero,
        placeholder: const Text('Length'),
        onChanged: (_) {},
      );
      expect(find.text('0:00'), findsNothing);

      await _pumpDropdown(
        tester,
        value: Duration.zero,
        min: Duration.zero,
        onChanged: (_) {},
      );
      expect(find.text('0:00'), findsOneWidget);
    });

    testWidgets('Issue 61: a disabled trigger is dimmed and emits nothing', (
      tester,
    ) async {
      Duration? picked;
      await _pumpDropdown(
        tester,
        value: const Duration(hours: 1),
        enabled: false,
        onChanged: (d) => picked = d,
      );
      await tester.tap(find.text('1:00'));
      await tester.pumpAndSettle();

      expect(picked, isNull);
      expect(
        tester
            .widget<Opacity>(
              find.descendant(
                of: find.byType(DurationPickerDropdown),
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
        0.5,
      );
    });
  });

  group('DurationPickerColumn', () {
    Future<void> pumpColumn(
      WidgetTester tester, {
      required ValueChanged<int> onSelected,
    }) async {
      await tester.pumpWidget(
        ShadApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              child: DurationPickerColumn(
                label: 'Minutes',
                options: const [0, 15, 30],
                selected: 15,
                formatter: (m) => m.toString().padLeft(2, '0'),
                onSelected: onSelected,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Issue 61: it shows its label and each option as formatted', (
      tester,
    ) async {
      await pumpColumn(tester, onSelected: (_) {});

      expect(find.text('Minutes'), findsOneWidget);
      for (final option in ['00', '15', '30']) {
        expect(find.text(option), findsOneWidget);
      }
    });

    testWidgets('Issue 61: only the selected option is emphasised', (
      tester,
    ) async {
      await pumpColumn(tester, onSelected: (_) {});

      FontWeight? weightOf(String text) =>
          tester.widget<Text>(find.text(text)).style!.fontWeight;
      expect(weightOf('15'), FontWeight.w600);
      expect(weightOf('00'), FontWeight.normal);
      expect(weightOf('30'), FontWeight.normal);
    });

    testWidgets('Issue 61: tapping an option reports its value, not its '
        'text', (tester) async {
      final picked = <int>[];
      await pumpColumn(tester, onSelected: picked.add);

      await tester.tap(find.text('00'));
      await tester.tap(find.text('30'));

      expect(picked, [0, 30]);
    });
  });
}
