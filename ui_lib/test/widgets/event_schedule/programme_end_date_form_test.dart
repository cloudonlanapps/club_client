import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

/// The local day [days] from today.
DateTime _day(int days) {
  final t = DateTime.now().add(Duration(days: days));
  return DateTime(t.year, t.month, t.day);
}

Future<ProgrammeEndDateFormState> _pump(
  WidgetTester tester, {
  required bool reasonRequired,
  DateTime? initialDay,
}) async {
  tester.view.physicalSize = const Size(1000, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: ProgrammeEndDateForm(
          initialDay: initialDay,
          reasonRequired: reasonRequired,
          resultOf: (day) => 'Last session: day ${day.day}.',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.state<ProgrammeEndDateFormState>(
    find.byType(ProgrammeEndDateForm),
  );
}

Future<void> _pick(
  WidgetTester tester,
  ProgrammeEndDateFormState state,
  DateTime day,
) async {
  state.formKey.currentState!.setFieldValue<DateTime?>(
    ProgrammeEndDateForm.lastDayId,
    day,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Issue 39: the form states what the chosen day gives before '
      'saving', (tester) async {
    final state = await _pump(tester, reasonRequired: true);
    expect(find.textContaining('Last session'), findsNothing);

    await _pick(tester, state, _day(9));

    expect(find.text('Last session: day ${_day(9).day}.'), findsOneWidget);
  });

  testWidgets('Issue 39: setting an end date needs a reason', (tester) async {
    final state = await _pump(tester, reasonRequired: true);
    await _pick(tester, state, _day(9));

    expect(state.validate(), isNull);
    await tester.pump();
    expect(
      find.text(ProgrammeEndDateFormValidators.reasonRequiredMessage),
      findsOneWidget,
    );

    await tester.enterText(find.byType(EditableText), ' Season over ');
    await tester.pump();
    expect(
      state.validate(),
      ProgrammeEndDateValue(lastDay: _day(9), reason: 'Season over'),
    );
  });

  testWidgets('Issue 39: changing an end date needs no reason, and the same '
      'day is not a change', (tester) async {
    final state = await _pump(
      tester,
      reasonRequired: false,
      initialDay: _day(9),
    );

    expect(state.isDirty, isFalse);
    expect(state.validate(), ProgrammeEndDateValue(lastDay: _day(9)));

    await _pick(tester, state, _day(4));
    expect(state.isDirty, isTrue);
    expect(state.validate()?.lastDay, _day(4));
  });

  testWidgets('Issue 39: a day before today cannot be chosen', (tester) async {
    final state = await _pump(tester, reasonRequired: false);

    await _pick(tester, state, _day(-1));
    expect(state.validate(), isNull);
    await tester.pump();
    expect(
      find.text(ProgrammeEndDateFormValidators.dayInPastMessage),
      findsOneWidget,
    );

    await _pick(tester, state, _day(0));
    expect(state.validate()?.lastDay, _day(0), reason: 'today is allowed');
  });

  test('Issue 39: ProgrammeEndDateFormValidators', () {
    final today = DateTime(2030, 5, 14, 16);
    const v = ProgrammeEndDateFormValidators.lastDay;
    expect(v(null, today: today), isNotNull);
    expect(v(DateTime(2030, 5, 13), today: today), isNotNull);
    expect(v(DateTime(2030, 5, 14), today: today), isNull);
    expect(v(DateTime(2031), today: today), isNull);

    const r = ProgrammeEndDateFormValidators.reason;
    expect(r('  ', required: true), isNotNull);
    expect(r('  ', required: false), isNull);
    expect(r('x' * 501, required: false), isNotNull);
  });
}
