import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/event_form/event_staff_coaches_field.dart';
import 'package:cl_club_forms/src/widgets/event_form/event_staff_form_strings.dart';
import 'package:cl_club_forms/src/widgets/event_form/event_staff_form_validators.dart';
import 'package:cl_club_forms/src/widgets/event_form/event_staff_organizer_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/form_harness.dart';

// Issue 61, points that do not apply to EventStaffForm: it has no rule
// across fields, nothing to type (both fields are driven by pickers), and no
// parameter hides or locks a field. Its in-form actions are Transfer, Add
// coaches, Undo and the remove (x) button of a coach row. Its other tests
// are in event_staff_form_test.dart.

const String _organizerId = EventFormFields.organizerNameId;
const String _coachesId = EventFormFields.coachNamesId;

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

/// Mounts the form. [transfers] are what the organizer picker answers, call
/// by call (null: cancelled); [picks] what the coach picker answers.
Future<EventStaffFormState> _pump(
  WidgetTester tester, {
  EventStaffMember? organizer = _organizer,
  List<EventStaffMember> coaches = const [_coachA, _coachB],
  List<EventStaffMember?> transfers = const [],
  List<List<EventStaffMember>?> picks = const [],
  bool enabled = true,
  Size size = kFormSurface,
}) async {
  final key = GlobalKey<EventStaffFormState>();
  final transferQueue = [...transfers];
  final pickQueue = [...picks];
  await pumpForm(
    tester,
    EventStaffForm(
      key: key,
      initialValues: {
        EventFormFields.organizerNameId: organizer,
        EventFormFields.coachNamesId: coaches,
      },
      enabled: enabled,
      onPickOrganizer: () async =>
          transferQueue.isEmpty ? null : transferQueue.removeAt(0),
      onPickCoaches: (_) async =>
          pickQueue.isEmpty ? null : pickQueue.removeAt(0),
    ),
    size: size,
  );
  return key.currentState!;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 61: EventStaffForm fields', () {
    testWidgets('Issue 61: its rows are Organizer, required, and Coaches', (
      tester,
    ) async {
      await _pump(tester);

      expect(rowLabels(tester), ['Organizer *', 'Coaches']);
      expectLabelsAreRows(tester);
      expect(
        tester.widget(fieldWithId(_organizerId)),
        isA<EventStaffOrganizerField>(),
      );
      expect(
        tester.widget(fieldWithId(_coachesId)),
        isA<EventStaffCoachesField>(),
      );
    });

    testWidgets('Issue 61: the organizer and every coach show their name, '
        'username and initials', (tester) async {
      await _pump(tester);

      final organizer = fieldWithId(_organizerId);
      for (final text in ['Olivia Organizer', '@org', 'OO']) {
        expect(
          find.descendant(of: organizer, matching: find.text(text)),
          findsOneWidget,
          reason: text,
        );
      }
      final coaches = fieldWithId(_coachesId);
      for (final text in [
        'Aaron Coach',
        '@coach_a',
        'AC',
        'Bea Coach',
        '@coach_b',
        'BC',
      ]) {
        expect(
          find.descendant(of: coaches, matching: find.text(text)),
          findsOneWidget,
          reason: text,
        );
      }
      // One remove action per coach, in the order seeded.
      expect(_removeButtons(), findsNWidgets(2));
      expect(
        tester.getTopLeft(find.text('Aaron Coach')).dy,
        lessThan(tester.getTopLeft(find.text('Bea Coach')).dy),
      );
    });
  });

  group('Issue 61: EventStaffForm validation', () {
    testWidgets('Issue 61: with no organizer the refusal shows on the '
        'organizer field, not on the coaches', (tester) async {
      final form = await _pump(tester, organizer: null);

      expect(form.validate(), isNull);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: fieldWithId(_organizerId),
          matching: find.text(EventStaffFormValidators.organizerRequired),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: fieldWithId(_coachesId),
          matching: find.text(EventStaffFormValidators.organizerRequired),
        ),
        findsNothing,
      );
    });

    testWidgets('Issue 61: an event with an organizer and no coach is '
        'valid: coaches are optional', (tester) async {
      final form = await _pump(tester, coaches: const []);

      expect(form.validate(), isNotNull);
    });
  });

  group('Issue 61: EventStaffForm values', () {
    testWidgets('Issue 61: validate returns a username and a list of '
        'usernames under the two ids, and nothing else', (tester) async {
      final form = await _pump(tester);

      final values = form.validate()!;

      expect(values.keys, [_organizerId, _coachesId]);
      expect(values[_organizerId], isA<String>());
      expect(values[_coachesId], isA<List<String>>());
      expect(values, {
        _organizerId: 'org',
        _coachesId: ['coach_a', 'coach_b'],
      });
    });

    testWidgets('Issue 61: picked coaches are appended in the order '
        'picked', (tester) async {
      final form = await _pump(
        tester,
        coaches: const [_coachB],
        picks: const [
          [_coachC, _coachA],
        ],
      );

      await _tap(tester, _button(EventStaffFormStrings.addCoaches));

      expect(form.validate()![_coachesId], ['coach_b', 'coach_c', 'coach_a']);
      expect(find.text(EventStaffFormStrings.noCoaches), findsNothing);
    });

    testWidgets('Issue 61: every coach removed leaves an empty list, the '
        'rows still shown struck through', (tester) async {
      final form = await _pump(tester);

      await _tap(tester, _removeButtons().first);
      await _tap(tester, _removeButtons().first);

      expect(form.validate()![_coachesId], isEmpty);
      expect(_removeButtons(), findsNothing);
      expect(_button(EventStaffFormStrings.undo), findsNWidgets(2));
      expect(find.text(EventStaffFormStrings.noCoaches), findsNothing);
      for (final name in ['Aaron Coach', 'Bea Coach']) {
        expect(
          tester.widget<Text>(find.text(name)).style!.decoration,
          TextDecoration.lineThrough,
        );
      }
    });

    testWidgets('Issue 61: a cancelled Add coaches changes nothing', (
      tester,
    ) async {
      final form = await _pump(tester, picks: const [null]);

      await _tap(tester, _button(EventStaffFormStrings.addCoaches));

      expect(form.isDirty, isFalse);
      expect(form.validate()![_coachesId], ['coach_a', 'coach_b']);
    });
  });

  group('Issue 61: EventStaffForm isDirty', () {
    testWidgets('Issue 104: the form opens with its initialValues map, '
        'clean, and a removed coach makes it dirty', (tester) async {
      final form = await _pump(tester);

      expect(find.text('Olivia Organizer'), findsOneWidget);
      expect(find.text('Aaron Coach'), findsOneWidget);
      expect(find.text('Bea Coach'), findsOneWidget);
      expect(form.isDirty, isFalse);

      await _tap(tester, _removeButtons().first);
      expect(form.isDirty, isTrue);
    });

    testWidgets('Issue 104: with nothing in initialValues the form opens '
        'unassigned with no coach, clean', (tester) async {
      final key = GlobalKey<EventStaffFormState>();
      await pumpForm(
        tester,
        EventStaffForm(
          key: key,
          initialValues: const {},
          onPickOrganizer: () async => null,
          onPickCoaches: (_) async => null,
        ),
      );

      expect(_removeButtons(), findsNothing);
      expect(key.currentState!.isDirty, isFalse);
    });

    testWidgets('Issue 61: the organizer transferred, then transferred '
        'back', (tester) async {
      final form = await _pump(
        tester,
        transfers: const [_coachC, _organizer],
      );
      expect(form.isDirty, isFalse);

      await _tap(tester, _button(EventStaffFormStrings.transfer));
      expect(form.isDirty, isTrue);
      expect(find.text('Cara Coach'), findsOneWidget);

      await _tap(tester, _button(EventStaffFormStrings.transfer));
      expect(form.isDirty, isFalse);
      expect(find.text('Olivia Organizer'), findsOneWidget);
    });

    testWidgets('Issue 61: an organizer picked for an event without one '
        'makes it dirty', (tester) async {
      final form = await _pump(
        tester,
        organizer: null,
        transfers: const [_coachC],
      );
      expect(form.isDirty, isFalse);

      await _tap(tester, _button(EventStaffFormStrings.transfer));

      expect(form.isDirty, isTrue);
    });

    testWidgets('Issue 61: a removed coach picked again is not appended: '
        'the removal stands and the form stays dirty', (tester) async {
      final form = await _pump(
        tester,
        picks: const [
          [_coachA],
        ],
      );

      await _tap(tester, _removeButtons().first);
      await _tap(tester, _button(EventStaffFormStrings.addCoaches));

      expect(form.validate()![_coachesId], ['coach_b']);
      expect(form.isDirty, isTrue);
    });
  });

  group('Issue 61: EventStaffForm and the server', () {
    testWidgets('Issue 61: what the server refuses shows on the organizer '
        'and on the coaches, and inline', (tester) async {
      final form = await _pump(tester);

      await expectShowsServerErrors(tester, form, _organizerId);
      await expectShowsServerErrors(tester, form, _coachesId);
    });

    testWidgets('Issue 61: after a refusal the form validates and returns '
        'its values again', (tester) async {
      final form = await _pump(tester, transfers: const [_coachC]);

      form.showErrors(
        fieldErrors: const {_organizerId: 'Not a member any more.'},
        formError: 'Could not update the staff.',
      );
      await tester.pumpAndSettle();
      expect(find.text('Not a member any more.'), findsOneWidget);
      expect(find.text('Could not update the staff.'), findsOneWidget);

      await _tap(tester, _button(EventStaffFormStrings.transfer));
      final values = form.validate();
      await tester.pumpAndSettle();

      expect(values, {
        _organizerId: 'coach_c',
        _coachesId: ['coach_a', 'coach_b'],
      });
      expect(find.text('Not a member any more.'), findsNothing);
      expect(find.text('Could not update the staff.'), findsNothing);
    });
  });

  group('Issue 61: EventStaffForm disabled', () {
    testWidgets('Issue 61: with enabled false no picker is asked and Undo '
        'does not answer', (tester) async {
      var organizerAsked = 0;
      var coachesAsked = 0;
      final enabled = ValueNotifier<bool>(true);
      addTearDown(enabled.dispose);
      final key = GlobalKey<EventStaffFormState>();
      await pumpForm(
        tester,
        ValueListenableBuilder<bool>(
          valueListenable: enabled,
          builder: (context, value, _) => EventStaffForm(
            key: key,
            enabled: value,
            initialValues: const {
              EventFormFields.organizerNameId: _organizer,
              EventFormFields.coachNamesId: [_coachA, _coachB],
            },
            onPickOrganizer: () async {
              organizerAsked++;
              return _coachC;
            },
            onPickCoaches: (_) async {
              coachesAsked++;
              return const [_coachC];
            },
          ),
        ),
      );
      // Stage a removal while the form still answers, then turn it off, as
      // a host does while it saves.
      await _tap(tester, _removeButtons().first);
      enabled.value = false;
      await tester.pumpAndSettle();

      for (final finder in [
        _button(EventStaffFormStrings.transfer),
        _button(EventStaffFormStrings.addCoaches),
        _button(EventStaffFormStrings.undo),
        _removeButtons(),
      ]) {
        expect(finder, findsOneWidget);
        expect(tester.widget<ShadButton>(finder).enabled, isFalse);
        await tester.tap(finder, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      expect(organizerAsked, 0);
      expect(coachesAsked, 0);
      expect(key.currentState!.validate(), {
        _organizerId: 'org',
        _coachesId: ['coach_b'],
      });

      // Turned on again, the staged removal is still there to undo.
      enabled.value = true;
      await tester.pumpAndSettle();
      await _tap(tester, _button(EventStaffFormStrings.undo));
      expect(key.currentState!.isDirty, isFalse);
    });
  });

  group('Issue 61: EventStaffForm layout', () {
    const longName = 'Maximiliana Alexandrina Featherstonehaugh-Cholmondeley';
    const longOrganizer = EventStaffMember(
      username: 'maximiliana_alexandrina_featherstonehaugh_cholmondeley',
      displayName: longName,
    );
    const longCoach = EventStaffMember(
      username: 'bartholomew_montgomery_fitzwilliam_the_third_of_his_name',
      displayName: 'Bartholomew Montgomery Fitzwilliam the Third of His Name',
    );

    testWidgets('Issue 61: it fits a phone, long names cut short beside '
        'their actions', (tester) async {
      await _pump(
        tester,
        organizer: longOrganizer,
        coaches: const [longCoach, _coachA],
        size: kPhoneSurface,
      );
      expect(tester.takeException(), isNull);

      // A struck-through row with Undo, the widest action, fits too.
      await _tap(tester, _removeButtons().first);
      expect(tester.takeException(), isNull);
      expect(tester.widget<Text>(find.text(longName)).maxLines, 1);
      expect(
        tester.getRect(_button(EventStaffFormStrings.undo)).right,
        lessThanOrEqualTo(kPhoneSurface.width),
      );
    });

    testWidgets('Issue 61: an unassigned organizer and no coaches fit a '
        'phone', (tester) async {
      await _pump(
        tester,
        organizer: null,
        coaches: const [],
        size: kPhoneSurface,
      );

      expect(tester.takeException(), isNull);
      expect(find.text(EventStaffFormStrings.unassigned), findsOneWidget);
      expect(find.text(EventStaffFormStrings.noCoaches), findsOneWidget);
    });

    testWidgets('Issue 61: its only buttons are Transfer, Add coaches, Undo '
        'and the remove action', (tester) async {
      await _pump(tester);
      await _tap(tester, _removeButtons().first);

      expectNoHostChrome(
        tester,
        allowedButtonTexts: {
          EventStaffFormStrings.transfer,
          EventStaffFormStrings.addCoaches,
          EventStaffFormStrings.undo,
        },
      );
      // Transfer, Add coaches, one Undo and one remove: nothing that saves.
      expect(find.byType(ShadButton), findsNWidgets(4));
      expect(find.text('Save'), findsNothing);
    });
  });
}
