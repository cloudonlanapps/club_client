import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Widget _wrap(Widget child) => ShadApp(home: Scaffold(body: child));

void main() {
  group('Issue 33: AgeEligibilityText.sentence', () {
    test('Issue 33: both bounds read "aged 5 to 18"', () {
      expect(
        AgeEligibilityText.sentence(
          minAge: const FormAge(years: 5),
          maxAge: const FormAge(years: 18),
        ),
        'Open to members aged 5 to 18',
      );
    });

    test('Issue 33: a minimum alone reads "aged 5 and over"', () {
      expect(
        AgeEligibilityText.sentence(minAge: const FormAge(years: 5)),
        'Open to members aged 5 and over',
      );
    });

    test('Issue 33: a maximum alone reads "aged up to 18"', () {
      expect(
        AgeEligibilityText.sentence(maxAge: const FormAge(years: 18)),
        'Open to members aged up to 18',
      );
    });

    test('Issue 33: no bound has no sentence', () {
      expect(AgeEligibilityText.sentence(), isNull);
    });

    test('Issue 33: months and days are spelt out', () {
      expect(
        AgeEligibilityText.sentence(
          minAge: const FormAge(years: 5, months: 6),
          maxAge: const FormAge(years: 18, months: 1, days: 2),
        ),
        'Open to members aged 5 years 6 months to 18 years 1 month 2 days',
      );
    });
  });

  group('Issue 33: AgeEligibilityText.window', () {
    test('Issue 33: both dates and the reference day', () {
      expect(
        AgeEligibilityText.window(
          dobOnOrAfter: DateTime.utc(2007, 6, 16),
          dobOnOrBefore: DateTime.utc(2022, 6, 14),
          referenceDay: DateTime.utc(2026, 6, 15),
        ),
        'Born 16 Jun 2007 – 14 Jun 2022, counted on 15 Jun 2026.',
      );
    });

    test('Issue 33: one date alone', () {
      expect(
        AgeEligibilityText.window(
          dobOnOrAfter: DateTime.utc(2007, 6, 16),
          referenceDay: DateTime.utc(2026, 6, 15),
        ),
        'Born on or after 16 Jun 2007, counted on 15 Jun 2026.',
      );
      expect(
        AgeEligibilityText.window(
          dobOnOrBefore: DateTime.utc(2022, 6, 14),
          referenceDay: DateTime.utc(2026, 6, 15),
        ),
        'Born on or before 14 Jun 2022, counted on 15 Jun 2026.',
      );
    });

    test('Issue 33: no date has no line', () {
      expect(
        AgeEligibilityText.window(referenceDay: DateTime.utc(2026, 6, 15)),
        isNull,
      );
    });
  });

  testWidgets(
    'Issue 33: the summary shows the sentence and the dates beneath, muted',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          AgeEligibilitySummary(
            minAge: const FormAge(years: 5),
            maxAge: const FormAge(years: 18),
            dobOnOrAfter: DateTime.utc(2007, 6, 16),
            dobOnOrBefore: DateTime.utc(2022, 6, 14),
            referenceDay: DateTime.utc(2026, 6, 15),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Open to members aged 5 to 18.'), findsOneWidget);
      final window = find.text(
        'Born 16 Jun 2007 – 14 Jun 2022, counted on 15 Jun 2026.',
      );
      expect(window, findsOneWidget);
      final context = tester.element(window);
      expect(
        tester.widget<Text>(window).style?.color,
        ShadTheme.of(context).textTheme.muted.color,
      );
    },
  );

  testWidgets('Issue 33: the summary renders nothing without a bound', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const AgeEligibilitySummary()));
    await tester.pumpAndSettle();
    expect(find.byType(Text), findsNothing);
  });

  group('Issue 61: AgeEligibilityText', () {
    test('Issue 61: an age of whole years is the number alone', () {
      expect(AgeEligibilityText.age(const FormAge(years: 5)), '5');
      expect(AgeEligibilityText.age(const FormAge(years: 0)), '0');
    });

    test('Issue 61: an age under a year leaves the years out', () {
      expect(
        AgeEligibilityText.age(const FormAge(years: 0, months: 6)),
        '6 months',
      );
      expect(AgeEligibilityText.age(const FormAge(years: 0, days: 1)), '1 day');
    });

    test('Issue 61: a zero part between two others is left out', () {
      expect(
        AgeEligibilityText.age(const FormAge(years: 1, days: 10)),
        '1 year 10 days',
      );
    });

    test('Issue 61: count is singular for one, plural otherwise', () {
      expect(AgeEligibilityText.count(1, 'month'), '1 month');
      expect(AgeEligibilityText.count(2, 'month'), '2 months');
      expect(AgeEligibilityText.count(0, 'day'), '0 days');
    });

    test('Issue 61: a date is written as its UTC calendar day', () {
      expect(AgeEligibilityText.datePattern, 'd MMM yyyy');
      expect(AgeEligibilityText.date(DateTime.utc(2007, 6, 16)), '16 Jun 2007');
      expect(AgeEligibilityText.date(DateTime.utc(2007, 1, 5)), '5 Jan 2007');
      // The last second of the UTC day is still that day, whatever the
      // zone the tests run in.
      expect(
        AgeEligibilityText.date(
          DateTime.utc(2007, 6, 16, 23, 59, 59).toLocal(),
        ),
        '16 Jun 2007',
      );
    });

    test('Issue 61: the window without a reference day ends after the '
        'dates', () {
      expect(
        AgeEligibilityText.window(
          dobOnOrAfter: DateTime.utc(2007, 6, 16),
          dobOnOrBefore: DateTime.utc(2022, 6, 14),
        ),
        'Born 16 Jun 2007 – 14 Jun 2022.',
      );
      expect(
        AgeEligibilityText.window(dobOnOrBefore: DateTime.utc(2022, 6, 14)),
        'Born on or before 14 Jun 2022.',
      );
    });

    test('Issue 61: no date and no reference day has no line', () {
      expect(AgeEligibilityText.window(), isNull);
    });
  });

  group('Issue 61: AgeEligibilitySummary', () {
    testWidgets('Issue 61: with a band and no dates it shows the sentence '
        'alone', (tester) async {
      await tester.pumpWidget(
        _wrap(const AgeEligibilitySummary(minAge: FormAge(years: 5))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Open to members aged 5 and over.'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('Issue 61: dates without a band show nothing', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AgeEligibilitySummary(
            dobOnOrAfter: DateTime.utc(2007, 6, 16),
            dobOnOrBefore: DateTime.utc(2022, 6, 14),
            referenceDay: DateTime.utc(2026, 6, 15),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsNothing);
    });

    testWidgets('Issue 61: the sentence stands above the dates, a line gap '
        'apart', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AgeEligibilitySummary(
            maxAge: const FormAge(years: 18, months: 6),
            dobOnOrAfter: DateTime.utc(2007, 12, 16),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sentence = find.text(
        'Open to members aged up to 18 years 6 months.',
      );
      final window = find.text('Born on or after 16 Dec 2007.');
      expect(sentence, findsOneWidget);
      expect(window, findsOneWidget);
      expect(
        tester.getTopLeft(window).dy - tester.getBottomLeft(sentence).dy,
        AgeEligibilitySummary.lineGap,
      );
    });

    testWidgets('Issue 61: a long sentence wraps on a phone', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrap(
          AgeEligibilitySummary(
            minAge: const FormAge(years: 5, months: 11, days: 30),
            maxAge: const FormAge(years: 150, months: 11, days: 30),
            dobOnOrAfter: DateTime.utc(1876, 6, 16),
            dobOnOrBefore: DateTime.utc(2022, 6, 14),
            referenceDay: DateTime.utc(2026, 6, 15),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
