// Issue 92: evaluation's four forms follow one contract — `enabled`,
// `validate()`, `isDirty` and `showErrors` — and label and space their
// fields as the forms of cl_club_forms do.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/evaluation/common/evaluation_form_contract.dart';
import 'package:ui_lib/src/widgets/evaluation/item_form/evaluation_item_form_fields.dart'
    show EvaluationItemFormFields;
import 'package:ui_lib/src/widgets/evaluation/layout/evaluation_add_bar.dart';
import 'package:ui_lib/ui_lib.dart';

import 'evaluation_form_contract_support.dart';
import 'evaluation_test_helpers.dart';

void main() {
  group('Issue 92: a refused template name', () {
    testWidgets('Issue 92: after a "name taken" refusal, a new name '
        'validates and returns the template as a map', (tester) async {
      final key = GlobalKey<EvaluationTemplateCreateFormState>();
      await pumpContractForm(
        tester,
        contractTemplateForm(key: key, initialValues: contractTemplateValues()),
      );
      expect(key.currentState!.validate(), isNotNull);

      key.currentState!.showErrors(
        fieldErrors: {EvaluationTemplateCreateFormFields.nameId: 'Name taken.'},
      );
      await tester.pump();
      expect(find.text('Name taken.'), findsOneWidget);

      await tester.enterText(find.byType(EditableText).first, ' Edges ');
      await tester.pump();
      final values = key.currentState!.validate();
      await tester.pump();
      expect(values, {
        EvaluationTemplateCreateFormFields.nameId: 'Edges',
        EvaluationTemplateCreateFormFields.layoutId: sampleLayout,
      });
      expect(find.text('Name taken.'), findsNothing);
    });
  });

  group('Issue 92: the four evaluation forms share one contract', () {
    testWidgets('Issue 92: each form has enabled, validate() returning a '
        'map or null, isDirty and showErrors', (tester) async {
      final forms = <Widget Function({required bool on})>[
        ({required on}) => contractTemplateForm(
          enabled: on,
          initialValues: contractTemplateValues(),
        ),
        ({required on}) => contractStartForm(enabled: on, fixed: true),
        ({required on}) => EvaluationPeriodForm(enabled: on),
        ({required on}) => contractItemForm(qaItem, enabled: on),
      ];
      for (final build in forms) {
        await pumpContractForm(tester, build(on: true));
        final state = tester.state(
          find.byWidgetPredicate(
            (w) =>
                w is EvaluationTemplateCreateForm ||
                w is EvaluationStartForm ||
                w is EvaluationPeriodForm ||
                w is EvaluationItemForm,
          ),
        );
        expect(state, isA<EvaluationFormContract>(), reason: '$state');
        final contract = state as EvaluationFormContract;
        expect(contract.isDirty, isFalse, reason: '$state');
        expect(contract.validate(), isA<Map<String, dynamic>>());

        contract.showErrors(formError: 'Refused by the server.');
        await tester.pump();
        expect(find.text('Refused by the server.'), findsOneWidget);
        contract.validate();
        await tester.pump();
        expect(find.text('Refused by the server.'), findsNothing);

        // Turned off, every field of the form is off.
        await pumpContractForm(tester, build(on: false));
        final fields = tester
            .stateList<
              ShadFormBuilderFieldState<ShadFormBuilderField<dynamic>, dynamic>
            >(
              find.byWidgetPredicate((w) => w is ShadFormBuilderField),
            );
        expect(fields, isNotEmpty);
        expect(fields.every((f) => !f.enabled), isTrue, reason: '$state');
      }
    });

    test('Issue 92: no evaluation form keeps isSubmitting, handleSubmit, '
        'setNameError or showRefusal', () {
      final kept = <String>[];
      final files = Directory(
        'lib/src/widgets/evaluation',
      ).listSync(recursive: true).whereType<File>();
      for (final file in files) {
        final source = file.readAsStringSync();
        for (final name in const [
          'isSubmitting',
          'handleSubmit',
          'setNameError',
          'showRefusal',
        ]) {
          if (source.contains(name)) kept.add('${file.path}: $name');
        }
      }
      expect(kept, isEmpty);
    });

    testWidgets('Issue 92: EvaluationStartForm has isDirty', (tester) async {
      final key = GlobalKey<EvaluationStartFormState>();
      await pumpContractForm(tester, contractStartForm(key: key));
      expect(key.currentState!.isDirty, isFalse);
      await tester.tap(find.text('Choose a template'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skating').last);
      await tester.pumpAndSettle();
      expect(key.currentState!.isDirty, isTrue);
    });

    testWidgets('Issue 92: EvaluationItemForm turned off keeps its values '
        'and greys its own controls; readOnly still shows it frozen', (
      tester,
    ) async {
      await pumpContractForm(
        tester,
        contractItemForm(multiItem, enabled: false),
      );
      final inputs = tester.widgetList<ShadInput>(find.byType(ShadInput));
      expect(inputs, isNotEmpty);
      expect(inputs.every((i) => !i.enabled), isTrue);
      final add = tester.widget<ShadButton>(
        find.ancestor(
          of: find.text('Choice'),
          matching: find.byType(ShadButton),
        ),
      );
      expect(add.enabled && add.onPressed != null, isFalse);
      final form = tester.state<ShadFormState>(find.byType(ShadForm));
      expect(form.value[EvaluationItemFormFields.textId], multiItem.text);
      final absorbing = find.byWidgetPredicate(
        (w) => w is AbsorbPointer && w.child is ShadForm,
      );
      expect(absorbing, findsNothing);

      await pumpContractForm(
        tester,
        contractItemForm(multiItem, readOnly: true),
      );
      expect(absorbing, findsOneWidget);
    });
  });

  group('Issue 92: saving is not drawn as "may not edit"', () {
    testWidgets('Issue 92: while a template is created, the Sort tick and '
        'the add bar stay on screen, greyed', (tester) async {
      await pumpContractForm(
        tester,
        contractTemplateForm(
          enabled: false,
          initialValues: contractTemplateValues(),
        ),
      );
      final sort = tester.widget<ShadCheckbox>(
        find.ancestor(
          of: find.text('Sort'),
          matching: find.byType(ShadCheckbox),
        ),
      );
      expect(sort.enabled, isFalse);
      final addBar = find.descendant(
        of: find.byType(EvaluationAddBar).last,
        matching: find.byType(ShadButton),
      );
      expect(addBar, findsOneWidget);
      expect(tester.widget<ShadButton>(addBar).onPressed, isNull);
    });

    testWidgets('Issue 92: a layout editor turned off reports no change, '
        'and only a read-only one removes Sort and add', (tester) async {
      final emitted = <List<EvaluationLayoutEntry>>[];
      final edited = <EvaluationItemValue>[];
      Widget editor({bool enabled = true, bool readOnly = false}) =>
          EvaluationLayoutEditor(
            layout: sampleLayout,
            enabled: enabled,
            readOnly: readOnly,
            onLayoutChanged: emitted.add,
            onEditItem: (item) async {
              edited.add(item);
              return null;
            },
            onEditSectionTitle: (_) async => null,
          );
      await pumpContractForm(tester, editor(enabled: false));
      expect(find.text('Sort'), findsOneWidget);
      expect(find.byType(EvaluationAddBar), findsWidgets);
      await tester.tap(find.text('Sort'));
      await tester.tap(find.text(qaItem.text));
      await tester.pumpAndSettle();
      expect(find.byIcon(LucideIcons.arrowUp), findsNothing);
      expect(edited, isEmpty);
      expect(emitted, isEmpty);

      await pumpContractForm(tester, editor(readOnly: true));
      expect(find.text('Sort'), findsNothing);
      expect(find.byType(EvaluationAddBar), findsNothing);
    });
  });

  group('Issue 92: a refusal shows inside the form', () {
    testWidgets('Issue 92: a refusal of Start review shows inside the '
        'start form and goes on the next validate', (tester) async {
      final key = GlobalKey<EvaluationStartFormState>();
      await pumpContractForm(tester, contractStartForm(key: key, fixed: true));
      key.currentState!.showErrors(formError: 'Not eligible.');
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(EvaluationStartForm),
          matching: find.text('Not eligible.'),
        ),
        findsOneWidget,
      );
      expect(key.currentState!.validate(), isNotNull);
      await tester.pump();
      expect(find.text('Not eligible.'), findsNothing);
    });

    testWidgets('Issue 92: the period form shows a refusal through '
        'showErrors, and the next validate clears it', (tester) async {
      final key = GlobalKey<EvaluationPeriodFormState>();
      await pumpContractForm(tester, EvaluationPeriodForm(key: key));
      key.currentState!.showErrors(formError: 'Already exists.');
      await tester.pump();
      expect(find.text('Already exists.'), findsOneWidget);
      expect(key.currentState!.validate(), isNotNull);
      await tester.pump();
      expect(find.text('Already exists.'), findsNothing);
    });

    testWidgets('Issue 92: an answer the server named incomplete loses the '
        'message once it is answered and the evaluation validated again', (
      tester,
    ) async {
      final key = GlobalKey<EvaluationFillBodyState>();
      await pumpContractForm(
        tester,
        EvaluationFillBody(
          key: key,
          layout: const [EvaluationLayoutEntry.item(qaItem)],
          initialAnswers: const {},
          onAnswerChanged: (_, _) {},
        ),
      );
      key.currentState!.markIncomplete([qaItem.id!]);
      await tester.pump();
      expect(find.text('Complete this answer.'), findsOneWidget);

      await tester.enterText(find.byType(EditableText).first, 'Edges');
      await tester.pump();
      expect(key.currentState!.validateForSave(), isEmpty);
      await tester.pump();
      expect(find.text('Complete this answer.'), findsNothing);
    });
  });
}
