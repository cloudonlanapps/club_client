import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/event_form/event_staff_coaches_field.dart';
import 'package:cl_club_forms/src/widgets/event_form/event_staff_form_strings.dart';
import 'package:cl_club_forms/src/widgets/event_form/event_staff_form_validators.dart';
import 'package:cl_club_forms/src/widgets/event_form/event_staff_organizer_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Widget _wrap(Widget child) => ShadApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

const _organizer = EventStaffMember(
  username: 'org',
  displayName: 'Olivia Organizer',
);
const _coachA = EventStaffMember(
  username: 'coach_a',
  displayName: 'Aaron Coach',
);
const _coachB = EventStaffMember(
  username: 'coach_b',
  displayName: 'Bea Coach',
);
const _coachC = EventStaffMember(
  username: 'coach_c',
  displayName: 'Cara Coach',
);

EventStaffForm _editor(
  GlobalKey<EventStaffFormState> key, {
  EventStaffMember? transferTo,
  List<EventStaffMember> addCoaches = const [],
  EventStaffMember? organizer = _organizer,
  List<EventStaffMember> coaches = const [_coachA, _coachB],
}) {
  return EventStaffForm(
    key: key,
    initialOrganizer: organizer,
    initialCoaches: coaches,
    onPickOrganizer: () async => transferTo,
    onPickCoaches: (exclude) async =>
        addCoaches.where((c) => !exclude.contains(c.username)).toList(),
  );
}

void main() {
  testWidgets('Issue 678: seeded organizer + coaches validate, start clean', (
    tester,
  ) async {
    final key = GlobalKey<EventStaffFormState>();
    await tester.pumpWidget(_wrap(_editor(key)));
    await tester.pumpAndSettle();

    final values = key.currentState!.validate()!;
    expect(values[EventFormFields.organizerNameId], 'org');
    expect(values[EventFormFields.coachNamesId], const ['coach_a', 'coach_b']);
    expect(key.currentState!.isDirty, isFalse);
  });

  testWidgets(
    'Issue 678: removing a coach strikes it through and is revertible',
    (
      tester,
    ) async {
      final key = GlobalKey<EventStaffFormState>();
      await tester.pumpWidget(_wrap(_editor(key)));
      await tester.pumpAndSettle();

      // Remove the first coach (the ✕ ghost button on its row).
      await tester.tap(find.widgetWithIcon(ShadButton, LucideIcons.x).first);
      await tester.pumpAndSettle();

      // It's staged for removal: excluded from the value, dirty, Undo offered.
      expect(key.currentState!.isDirty, isTrue);
      expect(
        key.currentState!.validate()![EventFormFields.coachNamesId],
        const ['coach_b'],
      );
      expect(find.widgetWithText(ShadButton, 'Undo'), findsOneWidget);

      // Revert restores it and the form is clean again.
      await tester.tap(find.widgetWithText(ShadButton, 'Undo'));
      await tester.pumpAndSettle();
      expect(key.currentState!.isDirty, isFalse);
      expect(
        key.currentState!.validate()![EventFormFields.coachNamesId],
        const ['coach_a', 'coach_b'],
      );
    },
  );

  testWidgets('Issue 678: Transfer changes the organizer', (tester) async {
    final key = GlobalKey<EventStaffFormState>();
    await tester.pumpWidget(_wrap(_editor(key, transferTo: _coachC)));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ShadButton, 'Transfer'));
    await tester.pumpAndSettle();

    expect(key.currentState!.isDirty, isTrue);
    expect(
      key.currentState!.validate()![EventFormFields.organizerNameId],
      'coach_c',
    );
  });

  testWidgets('Issue 678: Add coaches appends to the coach list', (
    tester,
  ) async {
    final key = GlobalKey<EventStaffFormState>();
    await tester.pumpWidget(_wrap(_editor(key, addCoaches: const [_coachC])));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ShadButton, 'Add coaches'));
    await tester.pumpAndSettle();

    expect(key.currentState!.isDirty, isTrue);
    expect(
      key.currentState!.validate()![EventFormFields.coachNamesId],
      const ['coach_a', 'coach_b', 'coach_c'],
    );
  });

  group('Issue 57: EventStaffForm is a ShadForm', () {
    testWidgets('Issue 57: the organizer and the coaches are two fields of '
        'one ShadForm', (tester) async {
      final key = GlobalKey<EventStaffFormState>();
      await tester.pumpWidget(_wrap(_editor(key)));
      await tester.pumpAndSettle();

      expect(find.byType(ShadForm), findsOneWidget);
      expect(find.byType(EventStaffOrganizerField), findsOneWidget);
      expect(find.byType(EventStaffCoachesField), findsOneWidget);
      expect(
        key.currentState!.formKey.currentState!.fields.keys,
        unorderedEquals([
          EventFormFields.organizerNameId,
          EventFormFields.coachNamesId,
        ]),
      );
      expect(EventFormFields.organizerNameId, 'organizerName');
      expect(EventFormFields.coachNamesId, 'coachNames');
    });

    testWidgets('Issue 57: saving with no organizer is refused with a '
        'message', (tester) async {
      final key = GlobalKey<EventStaffFormState>();
      await tester.pumpWidget(
        _wrap(_editor(key, organizer: null, transferTo: _coachC)),
      );
      await tester.pumpAndSettle();

      expect(find.text(EventStaffFormStrings.unassigned), findsOneWidget);
      expect(key.currentState!.isDirty, isFalse);
      expect(
        find.text(EventStaffFormValidators.organizerRequired),
        findsNothing,
      );

      expect(key.currentState!.validate(), isNull);
      await tester.pumpAndSettle();
      expect(
        find.text(EventStaffFormValidators.organizerRequired),
        findsOneWidget,
      );
    });

    testWidgets('Issue 57: picking an organizer clears the message and lets '
        'the form save', (tester) async {
      final key = GlobalKey<EventStaffFormState>();
      await tester.pumpWidget(
        _wrap(_editor(key, organizer: null, transferTo: _coachC)),
      );
      await tester.pumpAndSettle();
      expect(key.currentState!.validate(), isNull);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ShadButton, 'Transfer'));
      await tester.pumpAndSettle();

      expect(find.text(EventStaffFormStrings.unassigned), findsNothing);
      expect(find.text('Cara Coach'), findsOneWidget);
      expect(
        find.text(EventStaffFormValidators.organizerRequired),
        findsNothing,
      );
      expect(key.currentState!.isDirty, isTrue);
      expect(key.currentState!.validate(), {
        EventFormFields.organizerNameId: 'coach_c',
        EventFormFields.coachNamesId: const ['coach_a', 'coach_b'],
      });
    });

    testWidgets('Issue 57: a cancelled Transfer keeps the organizer', (
      tester,
    ) async {
      final key = GlobalKey<EventStaffFormState>();
      await tester.pumpWidget(_wrap(_editor(key)));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ShadButton, 'Transfer'));
      await tester.pumpAndSettle();

      expect(key.currentState!.isDirty, isFalse);
      expect(
        key.currentState!.validate()![EventFormFields.organizerNameId],
        'org',
      );
    });

    testWidgets('Issue 57: Transfer, Add coaches, remove and Undo give the '
        'usernames the event keeps', (tester) async {
      final key = GlobalKey<EventStaffFormState>();
      await tester.pumpWidget(
        _wrap(_editor(key, transferTo: _coachC, addCoaches: const [_coachC])),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ShadButton, 'Transfer'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ShadButton, 'Add coaches'));
      await tester.pumpAndSettle();
      // Remove the first and the second coach, then take the first back.
      await tester.tap(find.widgetWithIcon(ShadButton, LucideIcons.x).first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithIcon(ShadButton, LucideIcons.x).first);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ShadButton, 'Undo'), findsNWidgets(2));
      await tester.tap(find.widgetWithText(ShadButton, 'Undo').first);
      await tester.pumpAndSettle();

      // The removed coach keeps its row, struck through.
      expect(find.text('Bea Coach'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Bea Coach')).style!.decoration,
        TextDecoration.lineThrough,
      );
      expect(key.currentState!.validate(), {
        EventFormFields.organizerNameId: 'coach_c',
        EventFormFields.coachNamesId: const ['coach_a', 'coach_c'],
      });
    });

    testWidgets('Issue 57: Add coaches excludes every listed coach, a '
        'removed one included', (tester) async {
      final key = GlobalKey<EventStaffFormState>();
      Set<String>? excluded;
      await tester.pumpWidget(
        _wrap(
          EventStaffForm(
            key: key,
            initialOrganizer: _organizer,
            initialCoaches: const [_coachA, _coachB],
            onPickOrganizer: () async => null,
            onPickCoaches: (exclude) async {
              excluded = {...exclude};
              // A picker that ignores the exclusion adds nobody twice.
              return const [_coachA, _coachC, _coachC];
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithIcon(ShadButton, LucideIcons.x).first);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ShadButton, 'Add coaches'));
      await tester.pumpAndSettle();

      expect(excluded, {'coach_a', 'coach_b'});
      expect(
        key.currentState!.validate()![EventFormFields.coachNamesId],
        const ['coach_b', 'coach_c'],
      );
    });

    testWidgets('Issue 57: isDirty compares the coaches kept, not the list '
        'object', (tester) async {
      final key = GlobalKey<EventStaffFormState>();
      await tester.pumpWidget(
        _wrap(_editor(key, addCoaches: const [_coachC])),
      );
      await tester.pumpAndSettle();
      expect(key.currentState!.isDirty, isFalse);

      // Removing a coach and taking it back leaves a new, equal list.
      await tester.tap(find.widgetWithIcon(ShadButton, LucideIcons.x).first);
      await tester.pumpAndSettle();
      expect(key.currentState!.isDirty, isTrue);
      await tester.tap(find.widgetWithText(ShadButton, 'Undo'));
      await tester.pumpAndSettle();
      expect(key.currentState!.isDirty, isFalse);

      // A coach added and then removed leaves the event as it was.
      await tester.tap(find.widgetWithText(ShadButton, 'Add coaches'));
      await tester.pumpAndSettle();
      expect(key.currentState!.isDirty, isTrue);
      await tester.tap(find.widgetWithIcon(ShadButton, LucideIcons.x).last);
      await tester.pumpAndSettle();
      expect(key.currentState!.isDirty, isFalse);
    });

    testWidgets('Issue 57: an event with no coaches says so and saves an '
        'empty list', (tester) async {
      final key = GlobalKey<EventStaffFormState>();
      await tester.pumpWidget(_wrap(_editor(key, coaches: const [])));
      await tester.pumpAndSettle();

      expect(find.text(EventStaffFormStrings.noCoaches), findsOneWidget);
      expect(key.currentState!.validate(), {
        EventFormFields.organizerNameId: 'org',
        EventFormFields.coachNamesId: const <String>[],
      });
    });

    testWidgets('Issue 57: a disabled form answers no action', (tester) async {
      final key = GlobalKey<EventStaffFormState>();
      await tester.pumpWidget(
        _wrap(
          EventStaffForm(
            key: key,
            enabled: false,
            initialOrganizer: _organizer,
            initialCoaches: const [_coachA],
            onPickOrganizer: () async => _coachC,
            onPickCoaches: (_) async => const [_coachC],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(ShadButton, 'Transfer'),
        warnIfMissed: false,
      );
      await tester.tap(
        find.widgetWithText(ShadButton, 'Add coaches'),
        warnIfMissed: false,
      );
      await tester.tap(
        find.widgetWithIcon(ShadButton, LucideIcons.x),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(key.currentState!.isDirty, isFalse);
    });
  });
}
