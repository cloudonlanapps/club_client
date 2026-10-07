import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/event_form/event_staff_coaches_field.dart';
import 'package:cl_club_forms/src/widgets/event_form/event_staff_form_strings.dart';
import 'package:cl_club_forms/src/widgets/event_form/event_staff_form_validators.dart';
import 'package:cl_club_forms/src/widgets/event_form/event_staff_organizer_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/form_harness.dart';

// The two custom fields of EventStaffForm, each mounted alone under a bare
// ShadForm. They are fields, not forms: validate(), isDirty and showErrors
// are EventStaffForm's (event_staff_form_contract_test.dart).

const _organizer = EventStaffMember(
  username: 'org',
  displayName: 'Olivia Organizer',
);
const _coachA = EventStaffMember(
  username: 'coach_a',
  displayName: 'Aaron Coach',
);
const _coachB = EventStaffMember(username: 'coach_b', displayName: 'Bea Coach');
const _coachC = EventStaffMember(
  username: 'coach_c',
  displayName: 'Cara Coach',
);

Finder _button(String text) => find.widgetWithText(ShadButton, text);
Finder _removeButtons() => find.widgetWithIcon(ShadButton, LucideIcons.x);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 61: EventStaffOrganizerField', () {
    Future<GlobalKey<ShadFormState>> pumpField(
      WidgetTester tester, {
      EventStaffMember? initial,
      EventStaffMember? answer,
      bool enabled = true,
    }) async {
      final key = GlobalKey<ShadFormState>();
      await pumpForm(
        tester,
        ShadForm(
          key: key,
          child: EventStaffOrganizerField(
            id: 'who',
            initialValue: initial,
            enabled: enabled,
            validator: EventStaffFormValidators.organizer,
            onPick: () async => answer,
          ),
        ),
      );
      return key;
    }

    testWidgets('Issue 61: without a value it reads Unassigned and is '
        'refused by its validator', (tester) async {
      final form = await pumpField(tester);

      expect(find.text(EventStaffFormStrings.unassigned), findsOneWidget);
      expect(form.currentState!.value['who'], isNull);
      expect(form.currentState!.saveAndValidate(), isFalse);
      await tester.pumpAndSettle();
      expect(
        find.text(EventStaffFormValidators.organizerRequired),
        findsOneWidget,
      );
    });

    testWidgets('Issue 61: Transfer takes the picked member as its value', (
      tester,
    ) async {
      final form = await pumpField(tester, answer: _coachC);

      await _tap(tester, _button(EventStaffFormStrings.transfer));

      expect(form.currentState!.value['who'], _coachC);
      expect(find.text('Cara Coach'), findsOneWidget);
      expect(find.text(EventStaffFormStrings.unassigned), findsNothing);
      expect(form.currentState!.saveAndValidate(), isTrue);
    });

    testWidgets('Issue 61: a cancelled pick keeps the value it had', (
      tester,
    ) async {
      final form = await pumpField(tester, initial: _organizer);

      await _tap(tester, _button(EventStaffFormStrings.transfer));

      expect(form.currentState!.value['who'], _organizer);
      expect(find.text('Olivia Organizer'), findsOneWidget);
    });

    testWidgets('Issue 61: disabled, Transfer asks nobody', (tester) async {
      final form = await pumpField(
        tester,
        initial: _organizer,
        answer: _coachC,
        enabled: false,
      );

      await tester.tap(
        _button(EventStaffFormStrings.transfer),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(form.currentState!.value['who'], _organizer);
    });
  });

  group('Issue 61: EventStaffCoachesField', () {
    Future<GlobalKey<ShadFormState>> pumpField(
      WidgetTester tester, {
      List<EventStaffMember> initial = const [_coachA, _coachB],
      List<EventStaffMember>? answer,
      void Function(Set<String>)? onAsked,
    }) async {
      final key = GlobalKey<ShadFormState>();
      await pumpForm(
        tester,
        ShadForm(
          key: key,
          child: EventStaffCoachesField(
            id: 'coaches',
            initialValue: initial,
            onPick: (exclude) async {
              onAsked?.call(exclude);
              return answer;
            },
          ),
        ),
      );
      return key;
    }

    List<EventStaffMember> value(GlobalKey<ShadFormState> form) =>
        (form.currentState!.value['coaches'] as List).cast<EventStaffMember>();

    testWidgets('Issue 61: its value is the members themselves, in the '
        'order shown', (tester) async {
      final form = await pumpField(tester);

      expect(value(form), [_coachA, _coachB]);
    });

    testWidgets('Issue 61: a removed coach leaves the value at once and '
        'Undo puts it back in its place', (tester) async {
      final form = await pumpField(tester);

      await _tap(tester, _removeButtons().first);
      expect(value(form), [_coachB]);
      expect(find.text('Aaron Coach'), findsOneWidget);

      await _tap(tester, _button(EventStaffFormStrings.undo));
      expect(value(form), [_coachA, _coachB]);
      expect(
        tester.widget<Text>(find.text('Aaron Coach')).style!.decoration,
        isNot(TextDecoration.lineThrough),
      );
    });

    testWidgets('Issue 61: Add coaches tells the picker who is listed and '
        'appends only the new ones, once each', (tester) async {
      Set<String>? asked;
      final form = await pumpField(
        tester,
        answer: const [_coachB, _coachC, _coachC],
        onAsked: (exclude) => asked = {...exclude},
      );

      await _tap(tester, _button(EventStaffFormStrings.addCoaches));

      expect(asked, {'coach_a', 'coach_b'});
      expect(value(form), [_coachA, _coachB, _coachC]);
      expect(find.text('Cara Coach'), findsOneWidget);
    });

    testWidgets('Issue 61: with no coach it says so, and the first one '
        'picked replaces the note', (tester) async {
      final form = await pumpField(
        tester,
        initial: const [],
        answer: const [_coachC],
      );
      expect(find.text(EventStaffFormStrings.noCoaches), findsOneWidget);
      expect(value(form), isEmpty);

      await _tap(tester, _button(EventStaffFormStrings.addCoaches));

      expect(find.text(EventStaffFormStrings.noCoaches), findsNothing);
      expect(value(form), [_coachC]);
    });

    testWidgets('Issue 61: resetting the form brings back the first rows, '
        'none struck through', (tester) async {
      final form = await pumpField(tester, answer: const [_coachC]);
      await _tap(tester, _removeButtons().first);
      await _tap(tester, _button(EventStaffFormStrings.addCoaches));
      expect(value(form), [_coachB, _coachC]);

      form.currentState!.reset();
      await tester.pumpAndSettle();

      expect(value(form), [_coachA, _coachB]);
      expect(find.text('Cara Coach'), findsNothing);
      expect(_button(EventStaffFormStrings.undo), findsNothing);
      expect(_removeButtons(), findsNWidgets(2));
    });
  });
}
