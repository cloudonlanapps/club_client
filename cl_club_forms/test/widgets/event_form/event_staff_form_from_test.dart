// A programme changes its organizer and coaches from a session onward, so
// its editor asks for that session (club_client#118).
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_club_forms/src/widgets/event_form/event_staff_form_strings.dart';
import 'package:cl_club_forms/src/widgets/event_form/event_staff_form_validators.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/programme_from_session_field.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/programme_schedule_adjust_form_validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/form_harness.dart';

const _organizer = EventStaffMember(
  username: 'org',
  displayName: 'Olivia Organizer',
);

final List<DateTime> _options = [
  DateTime.utc(2030, 5, 14, 6),
  DateTime.utc(2030, 5, 21, 6),
];

Future<EventStaffFormState> _pump(
  WidgetTester tester, {
  List<DateTime>? fromOptions,
  DateTime? from,
}) async {
  final key = GlobalKey<EventStaffFormState>();
  await pumpForm(
    tester,
    EventStaffForm(
      key: key,
      initialValues: {
        EventFormFields.organizerNameId: _organizer,
        EventFormFields.coachNamesId: const <EventStaffMember>[],
        EventFormFields.effectiveFromId: ?from,
      },
      fromOptions: fromOptions,
      onPickOrganizer: () async => null,
      onPickCoaches: (_) async => null,
    ),
  );
  return key.currentState!;
}

void main() {
  testWidgets('Issue 118: with From sessions the form asks for one and '
      'returns it', (tester) async {
    final form = await _pump(
      tester,
      fromOptions: _options,
      from: _options.first,
    );

    expect(find.byType(ProgrammeFromSessionField), findsOneWidget);
    expect(
      find.text(
        EventStaffFormStrings.effectLine(
          ProgrammeFromSessionField.textOf(_options.first),
        ),
      ),
      findsOneWidget,
    );
    expect(
      form.validate()?[EventFormFields.effectiveFromId],
      _options.first,
    );
    expect(form.isDirty, isFalse);
  });

  testWidgets('Issue 118: without From sessions the form asks for none', (
    tester,
  ) async {
    final form = await _pump(tester);

    expect(find.byType(ProgrammeFromSessionField), findsNothing);
    expect(
      form.validate()!.containsKey(EventFormFields.effectiveFromId),
      isFalse,
    );
  });

  testWidgets('Issue 118: a From session must be chosen', (tester) async {
    final form = await _pump(tester, fromOptions: _options);

    expect(form.validate(), isNull);
    await tester.pump();
    expect(
      find.text(ProgrammeScheduleAdjustFormValidators.fromRequiredMessage),
      findsOneWidget,
    );
  });

  testWidgets('Issue 118: a programme with no upcoming session cannot be '
      'saved, and says why', (tester) async {
    final form = await _pump(tester, fromOptions: const []);

    expect(form.validate(), isNull);
    await tester.pump();
    expect(
      find.text(EventStaffFormValidators.noUpcomingSession),
      findsOneWidget,
    );
  });
}
