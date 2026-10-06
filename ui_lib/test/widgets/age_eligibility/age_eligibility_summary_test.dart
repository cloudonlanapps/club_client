import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

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
}
