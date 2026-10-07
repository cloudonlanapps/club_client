import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _start = ShadTimeOfDay(hour: 18, minute: 0, second: 0);

final _date = DateTime(2030, 5, 14);

const _split = [
  SessionInput(name: 'Warm-up', startTime: '18:00', endTime: '18:30'),
  SessionInput(name: 'Match', startTime: '18:30', endTime: '20:00'),
];

OneOffScheduleValue _initial({List<SessionInput> sessions = const []}) =>
    OneOffScheduleValue(
      schedule: OneOffScheduleData(date: _date, startTime: _start),
      venueId: 7,
      sessions: sessions,
    );

Future<OneOffScheduleFormState> _pump(
  WidgetTester tester,
  OneOffScheduleValue initial, {
  DateTime? notBefore,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: OneOffScheduleForm(
            initialValue: initial,
            venues: const [
              EventVenueOption(id: 7, name: 'North Rink'),
              EventVenueOption(id: 9, name: 'Hall'),
            ],
            notBefore: notBefore,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.state<OneOffScheduleFormState>(find.byType(OneOffScheduleForm));
}

Future<void> _setSchedule(
  WidgetTester tester,
  OneOffScheduleFormState state,
  OneOffScheduleData schedule,
) async {
  state.formKey.currentState!.setFieldValue<OneOffScheduleData>(
    OneOffScheduleFormFields.scheduleId,
    schedule,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Issue 37: an unedited form is clean and validates to its '
      'seeded value', (tester) async {
    final initial = _initial(sessions: _split);
    final state = await _pump(tester, initial);

    expect(state.isDirty, isFalse);
    expect(state.validate(), {
      OneOffScheduleFormFields.scheduleId: initial.schedule,
      OneOffScheduleFormFields.venueId: initial.venueId,
      OneOffScheduleFormFields.sessionsId: initial.sessions,
    });
    expect(find.text('North Rink'), findsOneWidget);
  });

  testWidgets('Issue 37: the form has no recurrence input', (tester) async {
    await _pump(tester, _initial());

    expect(find.text('Days of Week'), findsNothing);
    expect(find.text('Training Days'), findsNothing);
    for (final label in ['Date *', 'Start Time *', 'Duration *', 'Venue *']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Sessions'), findsOneWidget);
  });

  testWidgets('Issue 37: a start before the present one is refused inline', (
    tester,
  ) async {
    final state = await _pump(
      tester,
      _initial(),
      notBefore: DateTime(2030, 5, 14, 18),
    );

    await _setSchedule(
      tester,
      state,
      OneOffScheduleData(
        date: _date,
        startTime: const ShadTimeOfDay(hour: 17, minute: 0, second: 0),
      ),
    );
    expect(state.validate(), isNull);
    await tester.pump();
    expect(
      find.text(OneOffScheduleFormValidators.postponeOnlyMessage),
      findsOneWidget,
    );

    await _setSchedule(
      tester,
      state,
      OneOffScheduleData(date: DateTime(2030, 5, 15), startTime: _start),
    );
    expect(state.validate(), isNotNull);
  });

  testWidgets('Issue 37: a new start time moves the same sessions, a new '
      'duration resets them', (tester) async {
    final state = await _pump(tester, _initial(sessions: _split));

    await _setSchedule(
      tester,
      state,
      OneOffScheduleData(
        date: _date,
        startTime: const ShadTimeOfDay(hour: 19, minute: 0, second: 0),
      ),
    );
    expect(state.currentValue.sessions, const [
      SessionInput(name: 'Warm-up', startTime: '19:00', endTime: '19:30'),
      SessionInput(name: 'Match', startTime: '19:30', endTime: '21:00'),
    ]);

    await _setSchedule(
      tester,
      state,
      OneOffScheduleData(
        date: _date,
        startTime: const ShadTimeOfDay(hour: 19, minute: 0, second: 0),
        durationMinutes: 90,
      ),
    );
    expect(state.currentValue.sessions, isEmpty);
    expect(state.isDirty, isTrue);
  });

  testWidgets('Issue 54: a refusal shows on the field it is about, or '
      'inline', (tester) async {
    final state = await _pump(tester, _initial(sessions: _split));

    state.showErrors(
      fieldErrors: const {
        OneOffScheduleFormFields.sessionsId: 'The sessions must add up.',
        OneOffScheduleFormFields.venueId: 'That venue no longer exists.',
      },
      formError: 'A one-off can only be moved later.',
    );
    await tester.pumpAndSettle();

    expect(find.text('The sessions must add up.'), findsOneWidget);
    expect(find.text('That venue no longer exists.'), findsOneWidget);
    expect(find.text('A one-off can only be moved later.'), findsOneWidget);
  });

  test('Issue 37: OneOffScheduleFormValidators.venue needs a venue', () {
    expect(OneOffScheduleFormValidators.venue(null), isNotNull);
    expect(OneOffScheduleFormValidators.venue(7), isNull);
  });
}
