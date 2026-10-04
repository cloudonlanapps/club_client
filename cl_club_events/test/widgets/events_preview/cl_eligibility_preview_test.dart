import 'package:cl_club_events/src/widgets/events_preview/cl_eligibility_preview.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

DateTime _ts(int day) => DateTime.utc(2026, 5, day);

Event eventFixture({
  Gender? gender,
  DateTime? dobOnOrAfterUtc,
  DateTime? dobOnOrBeforeUtc,
}) {
  return Event(
    id: 1,
    title: 'Test Event',
    description: '',
    type: EventType.camp,
    visibility: Visibility.public,
    venueId: 1,
    startTimeUtc: _ts(20),
    endTimeUtc: _ts(20).add(const Duration(hours: 2)),
    createdAtUtc: _ts(1),
    updatedAtUtc: _ts(5),
    gender: gender,
    dobOnOrAfterUtc: dobOnOrAfterUtc,
    dobOnOrBeforeUtc: dobOnOrBeforeUtc,
  );
}

Widget wrap(Widget child) {
  return ShadApp(home: Scaffold(body: child));
}

void main() {
  testWidgets(
    'Issue 258: all fields null renders Open to all',
    (tester) async {
      final event = eventFixture();
      await tester.pumpWidget(wrap(ClEligibilityPreview(event: event)));
      await tester.pump();

      expect(find.text('Eligibility'), findsOneWidget);
      expect(find.text('This event is open to all.'), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 258: gender only renders gender sentence and no DOB line',
    (tester) async {
      final event = eventFixture(gender: Gender.female);
      await tester.pumpWidget(wrap(ClEligibilityPreview(event: event)));
      await tester.pump();

      expect(find.text('Eligibility'), findsOneWidget);
      expect(find.text('This event is only for Girls.'), findsOneWidget);
      expect(find.text('This event is open to all.'), findsNothing);
      expect(
        find.textContaining('age-based eligibility'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Issue 258: DOB window only renders inclusive sentence',
    (tester) async {
      final event = eventFixture(
        dobOnOrAfterUtc: DateTime.utc(2010, 1, 15),
        dobOnOrBeforeUtc: DateTime.utc(2015, 12, 31),
      );
      await tester.pumpWidget(wrap(ClEligibilityPreview(event: event)));
      await tester.pump();

      expect(find.text('Eligibility'), findsOneWidget);
      expect(
        find.textContaining(
          'age-based eligibility, and permits only those who were born '
          'between',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('(both dates inclusive)'), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 258: DOB on-or-after only renders the open-ended after sentence',
    (tester) async {
      final event = eventFixture(dobOnOrAfterUtc: DateTime.utc(2010, 1, 15));
      await tester.pumpWidget(wrap(ClEligibilityPreview(event: event)));
      await tester.pump();

      expect(find.textContaining('born on or after'), findsOneWidget);
      expect(find.textContaining('born on or before'), findsNothing);
      expect(find.textContaining('between'), findsNothing);
    },
  );

  testWidgets(
    'Issue 258: DOB on-or-before only renders the open-ended before sentence',
    (tester) async {
      final event = eventFixture(dobOnOrBeforeUtc: DateTime.utc(2015, 12, 31));
      await tester.pumpWidget(wrap(ClEligibilityPreview(event: event)));
      await tester.pump();

      expect(find.textContaining('born on or before'), findsOneWidget);
      expect(find.textContaining('born on or after'), findsNothing);
      expect(find.textContaining('between'), findsNothing);
    },
  );

  testWidgets(
    'Issue 258: gender + DOB window renders both sentences',
    (tester) async {
      final event = eventFixture(
        gender: Gender.male,
        dobOnOrAfterUtc: DateTime.utc(2010, 1, 15),
        dobOnOrBeforeUtc: DateTime.utc(2015, 12, 31),
      );
      await tester.pumpWidget(wrap(ClEligibilityPreview(event: event)));
      await tester.pump();

      expect(find.text('This event is only for Boys.'), findsOneWidget);
      expect(
        find.textContaining('age-based eligibility'),
        findsOneWidget,
      );
      expect(find.text('This event is open to all.'), findsNothing);
    },
  );

  testWidgets(
    'Issue 258: preferNotToSay gender is treated as no constraint',
    (tester) async {
      final event = eventFixture(gender: Gender.preferNotToSay);
      await tester.pumpWidget(wrap(ClEligibilityPreview(event: event)));
      await tester.pump();

      expect(find.text('This event is open to all.'), findsOneWidget);
    },
  );
}
