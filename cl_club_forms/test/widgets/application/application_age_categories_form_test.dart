// Issue 321, ApplicationAgeCategoriesForm: the age groups printed on the
// form, the member's ticked. Each has a name (English required, the print
// languages offered), optional first and last birth dates and the genders
// it takes (none: all).
import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/account_user_form_harness.dart';
import '../../support/form_harness.dart';
import 'application_form_harness.dart';
import 'application_samples.dart';
import 'application_section_harness.dart';

const String _categories = ApplicationFormFields.ageCategoriesId;

List<Object?> _items() => [
  {
    'label': {'en': 'Under 12', 'mr': 'बारा वर्षांखालील'},
    'born_on_or_after': '2014-01-01',
  },
  {
    'label': {'en': 'Senior Women'},
    'born_on_or_before': '2007-12-31',
    'genders': ['female'],
  },
];

Widget _form({
  required GlobalKey<ApplicationAgeCategoriesFormState> key,
  List<Object?>? items,
  bool enabled = true,
}) => ApplicationAgeCategoriesForm(
  key: key,
  initialValues: {_categories: items ?? _items()},
  languages: ApplicationSamples.printLanguages,
  enabled: enabled,
);

Future<ApplicationAgeCategoriesFormState> _pump(
  WidgetTester tester, {
  List<Object?>? items,
}) async {
  final key = GlobalKey<ApplicationAgeCategoriesFormState>();
  await pumpForm(tester, _form(key: key, items: items));
  return key.currentState!;
}

void main() {
  group('Issue 321: ApplicationAgeCategoriesForm', () {
    testWidgets('Issue 321: a category shows its name per language, its '
        'birth dates and its genders', (tester) async {
      await _pump(tester, items: [_items().first]);

      expect(fieldIds(tester), [_categories]);
      expect(rowLabels(tester), [
        'Age categories',
        'Name (English) *',
        'Name (Marathi)',
        'Born on or after',
        'Born on or before',
        'Genders (none ticked: all)',
      ]);
      expect(find.text('Age limit applicable'), findsOneWidget);
      expect(find.text('1 Jan 2014'), findsOneWidget);
      expect(find.text('Pick a date'), findsOneWidget);
      expect(find.byType(ShadCheckbox), findsNWidgets(4));
      expectLabelsAreRows(tester);
      expectNoHostChrome(
        tester,
        allowedButtonTexts: const {
          'Add age category',
          '1 Jan 2014',
          'Pick a date',
        },
      );
    });

    testWidgets('Issue 321: the categories come back as the template holds '
        'them, absent dates and genders left out', (tester) async {
      final state = await _pump(tester);

      expect(state.isDirty, isFalse);
      expect(state.validate(), {
        _categories: [
          for (final item in _items())
            {...(item! as Map<String, Object?>), 'age_limit': true},
        ],
      });
    });

    testWidgets('Issue 321: a date is cleared and a gender ticked', (
      tester,
    ) async {
      final state = await _pump(tester);

      await tapIn(tester, _categories, find.byIcon(LucideIcons.x));
      await tapIn(tester, _categories, find.text('Male'));

      expect(state.isDirty, isTrue);
      expect(state.validate(), isNull);
      await tester.pump();
      expect(
        messageOn(
          _categories,
          'Category 1: Pick a birth date, or untick Age limit applicable',
        ),
        findsOneWidget,
      );

      await tapIn(tester, _categories, find.text('Age limit applicable'));
      expect((state.validate()![_categories] as List).first, {
        'label': {'en': 'Under 12', 'mr': 'बारा वर्षांखालील'},
        'age_limit': false,
        'genders': ['male'],
      });
    });

    testWidgets('Issue 321: an added category needs an English name', (
      tester,
    ) async {
      final state = await _pump(tester);

      await tapIn(tester, _categories, find.text('Add age category'));
      expect(state.validate(), isNull);
      await tester.pump();
      expect(
        messageOn(_categories, 'Category 3: Needs a name in English'),
        findsOneWidget,
      );

      await typeIn(tester, _categories, 4, 'Open');
      expect((state.validate()![_categories] as List).last, {
        'label': {'en': 'Open'},
        'age_limit': false,
      });
    });

    testWidgets('Issue 337: a new category has no age limit and shows no '
        'dates; ticked, it needs a birth date', (tester) async {
      final state = await _pump(tester, items: const []);

      await tapIn(tester, _categories, find.text('Add age category'));
      await typeIn(tester, _categories, 0, 'Open');
      expect(find.text('Born on or after'), findsNothing);
      expect(find.text('Born on or before'), findsNothing);
      expect(state.validate(), {
        _categories: [
          {
            'label': {'en': 'Open'},
            'age_limit': false,
          },
        ],
      });

      await tapIn(tester, _categories, find.text('Age limit applicable'));
      expect(find.text('Born on or after'), findsOneWidget);
      expect(find.text('Born on or before'), findsOneWidget);
      expect(state.validate(), isNull);
      await tester.pump();
      expect(
        messageOn(
          _categories,
          'Category 1: Pick a birth date, or untick Age limit applicable',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Issue 337: unticking the age limit sends no dates; ticking '
        'it again brings them back', (tester) async {
      final state = await _pump(tester, items: [_items().first]);

      await tapIn(tester, _categories, find.text('Age limit applicable'));
      expect(find.text('1 Jan 2014'), findsNothing);
      expect(state.isDirty, isTrue);
      expect(state.validate(), {
        _categories: [
          {
            'label': {'en': 'Under 12', 'mr': 'बारा वर्षांखालील'},
            'age_limit': false,
          },
        ],
      });

      await tapIn(tester, _categories, find.text('Age limit applicable'));
      expect(find.text('1 Jan 2014'), findsOneWidget);
      expect(state.isDirty, isFalse);
      expect(
        (state.validate()![_categories] as List).first,
        {..._items().first! as Map<String, Object?>, 'age_limit': true},
      );
    });

    testWidgets('Issue 337: overlapping categories are allowed', (
      tester,
    ) async {
      final items = [
        {
          'label': {'en': 'U12'},
          'born_on_or_after': '2013-01-01',
          'born_on_or_before': '2014-12-31',
        },
        {
          'label': {'en': 'U14'},
          'born_on_or_after': '2011-01-01',
          'born_on_or_before': '2014-12-31',
        },
      ];
      final state = await _pump(tester, items: items);

      expect(state.validate(), {
        _categories: [
          for (final item in items) {...item, 'age_limit': true},
        ],
      });
    });

    testWidgets('Issue 321: birth dates the wrong way round are refused', (
      tester,
    ) async {
      final state = await _pump(
        tester,
        items: [
          {
            'label': {'en': 'Odd'},
            'born_on_or_after': '2014-01-01',
            'born_on_or_before': '2013-12-31',
          },
        ],
      );

      expect(state.validate(), isNull);
      await tester.pump();
      expect(
        messageOn(
          _categories,
          'Category 1: The last birth date is before the first',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Issue 321: a refusal shows under the list or inline; off, '
        'nothing takes input', (tester) async {
      final state = await _pump(tester);
      await expectShowsServerErrors(tester, state, _categories);
      await expectSectionFormBasics(
        tester,
        ({required enabled}) => _form(
          key: GlobalKey<ApplicationAgeCategoriesFormState>(),
          enabled: enabled,
        ),
      );
    });
  });
}
