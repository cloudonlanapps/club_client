// OneOffScheduleFormField, the one-off cluster shared by the create form and
// OneOffScheduleForm, driven through its inputs (issue 61). Its handlers and
// its aggregate validator are covered in one_off_schedule_fields_test.dart.
import 'package:cl_calendar/cl_calendar.dart' show CLDatePickerFormField;
import 'package:cl_club_forms/src/models/one_off_schedule_data.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/one_off_schedule_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/camp_one_off_schedule_helpers.dart';
import '../support/form_harness.dart';

const _id = 'schedule';

/// The cluster in a bare `ShadForm`, with what its `onChanged` reported.
class _Host {
  final formKey = GlobalKey<ShadFormState>();
  final reported = <OneOffScheduleData?>[];

  Widget build({OneOffScheduleData? initial, bool enabled = true}) => ShadForm(
    key: formKey,
    child: OneOffScheduleFormField(
      id: _id,
      initialValue: initial,
      enabled: enabled,
      validator: OneOffScheduleFormField.aggregateValidator,
      onChanged: reported.add,
    ),
  );

  OneOffScheduleData? get value =>
      formKey.currentState!.value[_id] as OneOffScheduleData?;
}

OneOffScheduleData _seed() =>
    OneOffScheduleData(date: DateTime(2030, 5, 14), startTime: timeAt(18));

void main() {
  group('OneOffScheduleFormField.aggregateValidator bounds', () {
    test('Issue 61: one minute is the least duration accepted', () {
      expect(
        OneOffScheduleFormField.aggregateValidator(
          _seed().copyWith(durationMinutes: 1),
        ),
        isNull,
      );
      expect(
        OneOffScheduleFormField.aggregateValidator(
          _seed().copyWith(durationMinutes: 0),
        ),
        'Duration must be greater than 0',
      );
    });

    test('Issue 61: of several faults the first in form order is reported', () {
      expect(
        OneOffScheduleFormField.aggregateValidator(
          const OneOffScheduleData(durationMinutes: 0),
        ),
        'Date is required',
      );
      expect(
        OneOffScheduleFormField.aggregateValidator(
          OneOffScheduleData(date: DateTime(2030), durationMinutes: 0),
        ),
        'Start time is required',
      );
    });
  });

  group('OneOffScheduleFormField inputs', () {
    testWidgets('Issue 61: its three rows are labelled rows, all required', (
      tester,
    ) async {
      await pumpForm(tester, _Host().build(initial: _seed()));

      expect(rowLabels(tester), ['Date *', 'Start Time *', 'Duration *']);
    });

    testWidgets('Issue 61: an empty cluster opens on two hours and holds no '
        'value until an input changes', (tester) async {
      final host = _Host();
      await pumpForm(tester, host.build());

      expect(host.value, isNull);
      expect(textInRow('Duration', '2h'), findsOneWidget);
      expect(textInRow('Date', 'Pick a date'), findsOneWidget);

      await pickScheduleDate(tester, DateTime(2030, 5, 14));

      expect(host.value, OneOffScheduleData(date: DateTime(2030, 5, 14)));
      expect(textInRow('Date', '14 May 2030'), findsOneWidget);
    });

    testWidgets('Issue 61: typing the hour alone gives a start time on the '
        'hour, typing the minutes completes it', (tester) async {
      final host = _Host();
      await pumpForm(tester, host.build());
      final boxes = find.descendant(
        of: scheduleRow('Start Time'),
        matching: find.byType(EditableText),
      );
      expect(boxes, findsNWidgets(2), reason: 'hours and minutes, no seconds');

      await tester.enterText(boxes.first, '18');
      await tester.pumpAndSettle();
      expect(host.value!.startTime, timeAt(18));

      await tester.enterText(boxes.last, '20');
      await tester.pumpAndSettle();
      expect(host.value!.startTime, timeAt(18, 20));
    });

    testWidgets('Issue 61: every edit is reported to the host with the '
        'whole schedule', (tester) async {
      final host = _Host();
      await pumpForm(tester, host.build(initial: _seed()));

      await typeInRow(tester, 'Duration', '45m');
      expect(host.reported.last, _seed().copyWith(durationMinutes: 45));

      await pickScheduleDate(tester, DateTime(2030, 6, 1));
      expect(
        host.reported.last,
        OneOffScheduleData(
          date: DateTime(2030, 6, 1),
          startTime: timeAt(18),
          durationMinutes: 45,
        ),
      );
      expect(host.reported, hasLength(2));
    });

    for (final (text, minutes) in [
      ('3h', 180),
      ('1.5h', 90),
      ('1.5', 90),
      ('45m', 45),
      ('2h 15m', 135),
      ('2h15', 135),
      (' 1H 30M ', 90),
    ]) {
      testWidgets('Issue 61: a duration typed as "$text" is $minutes '
          'minutes', (tester) async {
        final host = _Host();
        await pumpForm(tester, host.build(initial: _seed()));

        await typeInRow(tester, 'Duration', text);

        expect(host.value!.durationMinutes, minutes);
      });
    }

    testWidgets('Issue 61: validating an empty cluster puts each message '
        'on its own row', (tester) async {
      final host = _Host();
      await pumpForm(tester, host.build());

      await typeInRow(tester, 'Duration', 'soon');
      expect(host.formKey.currentState!.saveAndValidate(), isFalse);
      await tester.pumpAndSettle();

      expect(textInRow('Date', 'Date is required'), findsOneWidget);
      expect(
        textInRow('Start Time', 'Start time is required'),
        findsOneWidget,
      );
      expect(
        textInRow('Duration', 'Duration must be greater than 0'),
        findsOneWidget,
      );
    });

    testWidgets('Issue 61: a complete cluster validates', (tester) async {
      final host = _Host();
      await pumpForm(tester, host.build(initial: _seed()));

      expect(host.formKey.currentState!.saveAndValidate(), isTrue);
      expect(host.value, _seed());
    });

    testWidgets('Issue 61: with enabled false neither picker nor the '
        'duration responds', (tester) async {
      final host = _Host();
      await pumpForm(tester, host.build(initial: _seed(), enabled: false));

      await tester.tap(
        find.byType(CLDatePickerFormField),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(scheduleDatePickerIsOpen(tester), isFalse);
      expect(
        tester
            .widget<ShadTimePickerFormField>(
              find.byType(ShadTimePickerFormField),
            )
            .enabled,
        isFalse,
      );
      expect(
        tester
            .widget<ShadInputFormField>(find.byType(ShadInputFormField))
            .enabled,
        isFalse,
      );
      expect(host.reported, isEmpty);
    });

    testWidgets('Issue 61: the date picker of an enabled cluster opens', (
      tester,
    ) async {
      await pumpForm(tester, _Host().build(initial: _seed()));

      await tester.tap(find.byType(CLDatePickerFormField));
      await tester.pumpAndSettle();

      expect(scheduleDatePickerIsOpen(tester), isTrue);
    });
  });

  group('OneOffScheduleFormField layout', () {
    testWidgets('Issue 61: on a wide surface the date has the left column '
        'to itself and the start time and duration share a row', (
      tester,
    ) async {
      await pumpForm(tester, _Host().build(initial: _seed()));

      final date = tester.getRect(scheduleRow('Date'));
      final time = tester.getRect(scheduleRow('Start Time'));
      final duration = tester.getRect(scheduleRow('Duration'));
      expect(date.width, time.width);
      expect(time.top, greaterThan(date.bottom));
      expect(duration.top, time.top);
      expect(duration.left, greaterThan(time.right));
    });

    testWidgets('Issue 61: at phone width the rows stack in one column and '
        'nothing overflows', (tester) async {
      await pumpForm(
        tester,
        _Host().build(initial: _seed()),
        size: kPhoneSurface,
      );

      expect(tester.takeException(), isNull);
      final date = tester.getRect(scheduleRow('Date'));
      final time = tester.getRect(scheduleRow('Start Time'));
      final duration = tester.getRect(scheduleRow('Duration'));
      expect(date.width, kPhoneSurface.width - 32);
      expect(time.top, greaterThan(date.bottom));
      expect(duration.top, greaterThan(time.bottom));
      expect(duration.left, time.left);
    });
  });
}
