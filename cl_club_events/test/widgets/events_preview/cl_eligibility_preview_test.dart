import 'package:cl_club_events/src/widgets/events_preview/cl_eligibility_preview.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

DateTime _ts(int day) => DateTime.utc(2026, 5, day);

Event eventFixture({
  Gender? gender,
  Age? minAge,
  Age? maxAge,
  DateTime? dobOnOrAfterUtc,
  DateTime? dobOnOrBeforeUtc,
  DateTime? eligibilityReferenceDayUtc,
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
    minAge: minAge,
    maxAge: maxAge,
    dobOnOrAfterUtc: dobOnOrAfterUtc,
    dobOnOrBeforeUtc: dobOnOrBeforeUtc,
    eligibilityReferenceDayUtc: eligibilityReferenceDayUtc,
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
      expect(find.textContaining('Open to members aged'), findsNothing);
      expect(find.textContaining('Born'), findsNothing);
    },
  );

  // The three DOB-window cases below read the age band since club_client#33:
  // the sentence is by age, with the server's dates beneath.
  testWidgets(
    'Issue 258: DOB window only renders inclusive sentence',
    (tester) async {
      final event = eventFixture(
        minAge: const Age(years: 5),
        maxAge: const Age(years: 18),
        dobOnOrAfterUtc: DateTime.utc(2007, 6, 16),
        dobOnOrBeforeUtc: DateTime.utc(2022, 6, 14),
        eligibilityReferenceDayUtc: DateTime.utc(2026, 6, 15),
      );
      await tester.pumpWidget(wrap(ClEligibilityPreview(event: event)));
      await tester.pump();

      expect(find.text('Eligibility'), findsOneWidget);
      expect(find.text('Open to members aged 5 to 18.'), findsOneWidget);
      expect(
        find.text('Born 16 Jun 2007 – 14 Jun 2022, counted on 15 Jun 2026.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Issue 258: DOB on-or-after only renders the open-ended after sentence',
    (tester) async {
      final event = eventFixture(
        maxAge: const Age(years: 18),
        dobOnOrAfterUtc: DateTime.utc(2007, 6, 16),
        eligibilityReferenceDayUtc: DateTime.utc(2026, 6, 15),
      );
      await tester.pumpWidget(wrap(ClEligibilityPreview(event: event)));
      await tester.pump();

      expect(find.text('Open to members aged up to 18.'), findsOneWidget);
      expect(
        find.text('Born on or after 16 Jun 2007, counted on 15 Jun 2026.'),
        findsOneWidget,
      );
      expect(find.textContaining('on or before'), findsNothing);
    },
  );

  testWidgets(
    'Issue 258: DOB on-or-before only renders the open-ended before sentence',
    (tester) async {
      final event = eventFixture(
        minAge: const Age(years: 5),
        dobOnOrBeforeUtc: DateTime.utc(2022, 6, 14),
        eligibilityReferenceDayUtc: DateTime.utc(2026, 6, 15),
      );
      await tester.pumpWidget(wrap(ClEligibilityPreview(event: event)));
      await tester.pump();

      expect(find.text('Open to members aged 5 and over.'), findsOneWidget);
      expect(
        find.text('Born on or before 14 Jun 2022, counted on 15 Jun 2026.'),
        findsOneWidget,
      );
      expect(find.textContaining('on or after'), findsNothing);
    },
  );

  testWidgets(
    'Issue 258: gender + DOB window renders both sentences',
    (tester) async {
      final event = eventFixture(
        gender: Gender.male,
        minAge: const Age(years: 5),
        maxAge: const Age(years: 18),
        dobOnOrAfterUtc: DateTime.utc(2007, 6, 16),
        dobOnOrBeforeUtc: DateTime.utc(2022, 6, 14),
      );
      await tester.pumpWidget(wrap(ClEligibilityPreview(event: event)));
      await tester.pump();

      expect(find.text('This event is only for Boys.'), findsOneWidget);
      expect(find.text('Open to members aged 5 to 18.'), findsOneWidget);
      expect(find.text('This event is open to all.'), findsNothing);
    },
  );

  testWidgets(
    'Issue 33: the dates and the reference day sit beneath the age sentence '
    'in muted text',
    (tester) async {
      final event = eventFixture(
        minAge: const Age(years: 5),
        maxAge: const Age(years: 18),
        dobOnOrAfterUtc: DateTime.utc(2007, 6, 16),
        dobOnOrBeforeUtc: DateTime.utc(2022, 6, 14),
        eligibilityReferenceDayUtc: DateTime.utc(2026, 6, 15),
      );
      await tester.pumpWidget(wrap(ClEligibilityPreview(event: event)));
      await tester.pump();

      final sentence = find.text('Open to members aged 5 to 18.');
      final window = find.text(
        'Born 16 Jun 2007 – 14 Jun 2022, counted on 15 Jun 2026.',
      );
      expect(sentence, findsOneWidget);
      expect(window, findsOneWidget);
      expect(
        tester.getTopLeft(window).dy,
        greaterThan(tester.getTopLeft(sentence).dy),
      );
      expect(
        tester.widget<Text>(window).style?.color,
        ShadTheme.of(tester.element(window)).textTheme.muted.color,
      );
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
