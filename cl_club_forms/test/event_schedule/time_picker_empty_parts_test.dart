// TimePickerEmptyParts (issue 66): the controller of a time picker learns
// that its hour or its minute box was emptied.
import 'package:cl_club_forms/src/widgets/event_schedule/time_picker_empty_parts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/form_harness.dart';

/// Mounts a picker of hours and minutes at 06:30 and returns its controller.
Future<ShadTimePickerController> _pump(
  WidgetTester tester, {
  required bool watched,
}) async {
  final controller = ShadTimePickerController(hour: 6, minute: 30, second: 0);
  addTearDown(controller.dispose);
  final picker = ShadTimePicker(controller: controller, showSeconds: false);
  await pumpForm(
    tester,
    watched
        ? TimePickerEmptyParts(controller: controller, child: picker)
        : picker,
  );
  return controller;
}

Finder _boxes() => find.descendant(
  of: find.byType(ShadTimePicker),
  matching: find.byType(EditableText),
);

Future<void> _type(WidgetTester tester, int box, String text) async {
  await tester.enterText(_boxes().at(box), text);
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 66: TimePickerEmptyParts', () {
    testWidgets('Issue 66: alone, the picker leaves its controller at the '
        'earlier hour when the hour is emptied', (tester) async {
      final controller = await _pump(tester, watched: false);

      await _type(tester, 0, '');

      expect(controller.hour, 6);
    });

    testWidgets('Issue 66: an emptied hour clears the hour of the '
        'controller, and tells its listeners', (tester) async {
      final controller = await _pump(tester, watched: true);
      var heard = 0;
      controller.addListener(() => heard++);

      await _type(tester, 0, '');

      expect(controller.hour, isNull);
      expect(controller.minute, 30);
      expect(controller.value, isNull);
      expect(heard, 1);
    });

    testWidgets('Issue 66: an emptied minute clears the minute of the '
        'controller', (tester) async {
      final controller = await _pump(tester, watched: true);

      await _type(tester, 1, '');

      expect(controller.hour, 6);
      expect(controller.minute, isNull);
      expect(controller.value, isNull);
    });

    testWidgets('Issue 66: the same hour typed again is a time again', (
      tester,
    ) async {
      final controller = await _pump(tester, watched: true);

      await _type(tester, 0, '');
      await _type(tester, 0, '6');

      expect(
        controller.value,
        const ShadTimeOfDay(hour: 6, minute: 30, second: 0),
      );
    });
  });
}
