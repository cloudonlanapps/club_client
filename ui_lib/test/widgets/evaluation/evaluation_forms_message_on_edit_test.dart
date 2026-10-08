// Issue 97: in each of evaluation's four forms the form-level message goes
// on the next edit, and no form clears it from its own `onChanged`.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/src/utils/evaluation_form_equality.dart';
import 'package:ui_lib/src/widgets/evaluation/common/evaluation_form_contract.dart';
import 'package:ui_lib/ui_lib.dart';

import 'evaluation_test_helpers.dart';

final Map<String, Widget Function()> _forms = {
  'EvaluationTemplateCreateForm': () => EvaluationTemplateCreateForm(
    initialValues: const {
      EvaluationTemplateCreateFormFields.nameId: 'Skating',
      EvaluationTemplateCreateFormFields.layoutId: sampleLayout,
    },
    onEditItem: (_) async => null,
    onEditSectionTitle: (_) async => null,
  ),
  'EvaluationStartForm': () => const EvaluationStartForm(
    templates: [(id: 1, label: 'Skating')],
    members: [(username: 'ana', label: 'Ana Rao')],
    events: [(id: 9, label: 'Spring camp')],
  ),
  'EvaluationPeriodForm': () => EvaluationPeriodForm(
    initialStart: DateTime(2026, 5),
    initialEnd: DateTime(2026, 5, 31),
  ),
  'EvaluationItemForm': () => EvaluationItemForm(
    kind: qaItem.kind,
    initialValues: EvaluationItemFormValues.fromItem(qaItem),
  ),
};

void main() {
  group('Issue 97: an evaluation form-level message goes on the next '
      'edit', () {
    for (final entry in _forms.entries) {
      testWidgets('Issue 97: ${entry.key}: the form-level message goes on '
          'the next edit of the form', (tester) async {
        const onForm = 'Could not save.';
        await tallSurface(tester);
        await tester.pumpWidget(wrapEvaluation(entry.value()));
        await tester.pumpAndSettle();
        final state = tester.allStates
            .whereType<EvaluationFormContract>()
            .first;
        final form = state.formKey.currentState!;
        state.showErrors(formError: onForm);
        await tester.pumpAndSettle();
        expect(find.text(onForm), findsOneWidget);
        // Frames alone, with nothing edited, leave the message.
        await tester.pump(const Duration(seconds: 1));
        expect(find.text(onForm), findsOneWidget);

        // The first of these that changes a value is the edit.
        final typed = find.byWidgetPredicate(
          (w) => w is EditableText && !w.readOnly,
        );
        final before = Map<String, dynamic>.of(form.value);
        final edits = <Future<void> Function()>[
          if (typed.evaluate().isNotEmpty)
            () => tester.enterText(typed.first, 'edited'),
          // A form of selects and dates: another first day.
          if (form.fields[EvaluationStartFormFields.periodStartId]
              case final start?)
            () async => start.didChange(DateTime(2026, 4)),
        ];
        var edited = false;
        for (final edit in edits) {
          await edit();
          await tester.pump();
          edited = !EvaluationFormEquality.mapsEqual(before, form.value);
          if (edited) break;
        }
        expect(edited, isTrue, reason: 'no field to edit');
        await tester.pumpAndSettle();
        expect(find.text(onForm), findsNothing, reason: 'message stayed');
      });
    }

    test('Issue 97: no evaluation form clears its form-level message '
        'itself when a field changes', () {
      final own = [
        for (final file in Directory(
          'lib/src/widgets/evaluation',
        ).listSync(recursive: true))
          if (file is File &&
              file.path.endsWith('.dart') &&
              !file.path.endsWith('evaluation_form_contract.dart') &&
              RegExp(
                r'setFormError\(null\)|formError = null',
              ).hasMatch(file.readAsStringSync()))
            file.path,
      ];
      expect(own, isEmpty);
    });
  });
}
