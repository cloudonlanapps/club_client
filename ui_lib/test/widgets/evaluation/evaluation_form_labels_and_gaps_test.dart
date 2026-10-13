// Issue 92: evaluation's four forms label and space their fields as the
// forms of cl_club_forms do.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/constants/form_spacing.dart';
import 'package:ui_lib/src/widgets/labeled_form_row.dart';
import 'package:ui_lib/ui_lib.dart';

import 'evaluation_form_contract_support.dart';
import 'evaluation_test_helpers.dart';

/// The form fields on screen that carry a label of their own.
Iterable<Widget> _fieldsLabellingThemselves(WidgetTester tester) => tester
    .widgetList(find.byWidgetPredicate((w) => w is ShadFormBuilderField))
    .where((w) => (w as ShadFormBuilderField).label != null);

/// A gap of cl_club_forms' `FormSpacing`, read from its source: the two
/// packages share no code.
double _clubFormsGap(String name) {
  final source = File(
    '../cl_club_forms/lib/src/constants/form_spacing.dart',
  ).readAsStringSync();
  final match = RegExp('double $name = (\\d+)').firstMatch(source);
  return double.parse(match!.group(1)!);
}

void main() {
  group('Issue 92: labels and gaps as in cl_club_forms', () {
    test('Issue 92: the label gap, the row gap and the section gap equal '
        "cl_club_forms'", () {
      expect(FormSpacing.labelGap, _clubFormsGap('labelGap'));
      expect(FormSpacing.rowGap, _clubFormsGap('rowGap'));
      expect(FormSpacing.sectionGap, _clubFormsGap('sectionGap'));
    });

    testWidgets('Issue 92: in the four forms every labelled field sits in '
        'the label row, and none labels itself', (tester) async {
      final forms = <(Widget, List<String>)>[
        (
          contractTemplateForm(initialValues: contractTemplateValues()),
          ['Template name *', 'Items *'],
        ),
        (
          contractStartForm(),
          ['Template *', 'Member *', 'Event', 'Period from', 'Period to'],
        ),
        (contractStartForm(fixed: true), ['Template', 'Member', 'Event']),
        (
          const EvaluationPeriodForm(),
          ['Event', 'Period from', 'Period to'],
        ),
        (contractItemForm(qaItem), ['Question *']),
        (contractItemForm(infoItem), ['Text (markdown) *']),
        (contractItemForm(multiItem), ['Question *', 'Choices *']),
        (
          contractItemForm(yesNoItem),
          ['Question *', 'Label for Yes', 'Label for No'],
        ),
        (
          contractItemForm(levelsItem),
          ['Question *', 'Scale', 'Levels *', 'Require a coach note for'],
        ),
        (
          contractItemForm(
            const EvaluationItemValue(
              kind: EvaluationItemKind.rating,
              text: 'Speed',
              scale: EvaluationRatingScale.stars(),
            ),
          ),
          ['Question *', 'Scale', 'Lowest *', 'Highest *'],
        ),
      ];
      for (final (form, labels) in forms) {
        await pumpContractForm(tester, form);
        expect(_fieldsLabellingThemselves(tester), isEmpty, reason: '$labels');
        for (final label in labels) {
          expect(
            find.descendant(
              of: find.byType(LabeledFormRow),
              matching: find.text(label),
            ),
            findsOneWidget,
            reason: label,
          );
        }
      }
    });

    testWidgets('Issue 92: a label sits 8 above its field and one row 16 '
        'above the next', (tester) async {
      Finder row(String label) => find.ancestor(
        of: find.text(label),
        matching: find.byType(LabeledFormRow),
      );
      Future<void> expectGaps(Widget form, List<String> labels) async {
        await pumpContractForm(tester, form);
        for (var i = 0; i < labels.length; i++) {
          final rect = tester.getRect(row(labels[i]));
          final label = tester.getRect(find.text(labels[i]));
          final field = tester.getRect(
            find
                .descendant(
                  of: row(labels[i]),
                  matching: find.byWidgetPredicate(
                    (w) => w is ShadFormBuilderField,
                  ),
                )
                .first,
          );
          expect(field.top - label.bottom, FormSpacing.labelGap);
          if (i == 0) continue;
          final above = tester.getRect(row(labels[i - 1]));
          expect(
            rect.top - above.bottom,
            FormSpacing.rowGap,
            reason: labels[i],
          );
        }
      }

      await expectGaps(contractTemplateForm(), ['Template name *', 'Items *']);
      await expectGaps(contractStartForm(), [
        'Template *',
        'Member *',
        'Event',
        'Period from',
        'Period to',
      ]);
      await expectGaps(const EvaluationPeriodForm(), [
        'Event',
        'Period from',
        'Period to',
      ]);
      await expectGaps(contractItemForm(multiItem), [
        'Question *',
        'Choices *',
      ]);
    });
  });
}
