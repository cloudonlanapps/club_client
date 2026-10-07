// EventVenueSelectField is one labelled select: nothing to type, no rule
// across fields, no `validate()` / `isDirty` / `showErrors` of its own (the
// forms that host it are tested for those) and no host chrome.
import 'package:cl_club_forms/src/widgets/event_create/event_create_form_fields.dart'
    show EventVenueOption;
import 'package:cl_club_forms/src/widgets/event_schedule/event_venue_select_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/form_harness.dart';
import '../support/programme_timetable_support.dart';

const String _id = 'venue';
const String _required = 'Pick a venue first';

const List<EventVenueOption> _venues = [
  EventVenueOption(id: 7, name: 'North Rink'),
  EventVenueOption(id: 9, name: 'Hall'),
];

Widget _field({int? initialValue, bool enabled = true}) =>
    EventVenueSelectField(
      id: _id,
      venues: _venues,
      initialValue: initialValue,
      enabled: enabled,
      validator: (value) => value == null ? _required : null,
    );

void main() {
  test('Issue 61: nameOf gives a venue its name, and its id when it is not '
      'offered', () {
    const field = EventVenueSelectField(id: _id, venues: _venues);
    expect(field.nameOf(9), 'Hall');
    expect(field.nameOf(42), '#42');
  });

  testWidgets('Issue 61: the picker is one required row labelled Venue, '
      'showing the placeholder while empty', (tester) async {
    final form = await pumpFieldInForm(tester, _field());

    expect(rowLabels(tester), ['Venue *']);
    expectLabelsAreRows(tester);
    expect(find.text(EventVenueSelectField.placeholder), findsOneWidget);
    expect(form.currentState!.value[_id], isNull);
  });

  testWidgets('Issue 61: it shows the seeded venue by name', (tester) async {
    final form = await pumpFieldInForm(tester, _field(initialValue: 9));

    expect(find.text('Hall'), findsOneWidget);
    expect(find.text(EventVenueSelectField.placeholder), findsNothing);
    expect(form.currentState!.value[_id], 9);
  });

  testWidgets('Issue 61: a seeded venue that is not offered shows as its id', (
    tester,
  ) async {
    final form = await pumpFieldInForm(tester, _field(initialValue: 42));

    expect(find.text('#42'), findsOneWidget);
    expect(form.currentState!.value[_id], 42);
  });

  testWidgets('Issue 61: opening it lists every venue, and picking one sets '
      'the value to its id', (tester) async {
    final form = await pumpFieldInForm(tester, _field(initialValue: 7));

    await tester.tap(find.text('North Rink'));
    await tester.pumpAndSettle();
    expect(find.text('Hall'), findsOneWidget);
    await tester.tap(find.text('Hall'));
    await tester.pumpAndSettle();

    expect(form.currentState!.value[_id], 9);
    expect(find.text('Hall'), findsOneWidget);
    expect(find.text('North Rink'), findsNothing);
  });

  testWidgets("Issue 61: the validator's message shows on the picker, and "
      'goes once a venue is chosen', (tester) async {
    final form = await pumpFieldInForm(tester, _field());

    expect(form.currentState!.saveAndValidate(), isFalse);
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: fieldWithId(_id), matching: find.text(_required)),
      findsOneWidget,
    );

    form.currentState!.setFieldValue<int>(_id, 7);
    await tester.pumpAndSettle();
    expect(form.currentState!.saveAndValidate(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text(_required), findsNothing);
  });

  testWidgets('Issue 61: disabled, the picker does not open', (tester) async {
    final form = await pumpFieldInForm(
      tester,
      _field(initialValue: 7, enabled: false),
    );

    await tester.tap(find.text('North Rink'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Hall'), findsNothing);
    expect(form.currentState!.value[_id], 7);
  });

  testWidgets('Issue 61: the picker fits a phone', (tester) async {
    await pumpFieldInForm(
      tester,
      _field(initialValue: 7),
      size: kPhoneSurface,
    );
    expect(tester.takeException(), isNull);
    expect(find.text('North Rink'), findsOneWidget);
  });
}
