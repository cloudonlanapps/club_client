// Issue 92: evaluation's four forms follow one contract — `enabled`,
// `validate()`, `isDirty` and `showErrors` — and label and space their
// fields as the forms of cl_club_forms do.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/constants/form_spacing.dart';
import 'package:ui_lib/src/widgets/evaluation/common/evaluation_form_contract.dart';
import 'package:ui_lib/src/widgets/evaluation/item_form/evaluation_item_form_fields.dart'
    show EvaluationItemFormFields;
import 'package:ui_lib/src/widgets/evaluation/layout/evaluation_add_bar.dart';
import 'package:ui_lib/src/widgets/labeled_form_row.dart';
import 'package:ui_lib/ui_lib.dart';

import 'evaluation_test_helpers.dart';

const List<EvaluationStartChoice> _templates = [(id: 1, label: 'Skating')];
const List<EvaluationStartMember> _members = [
  (username: 'ana', label: 'Ana Rao'),
];
const List<EvaluationStartChoice> _events = [(id: 9, label: 'Spring camp')];

Map<String, dynamic> _templateValues({String name = 'Skating'}) => {
  EvaluationTemplateCreateFormFields.nameId: name,
  EvaluationTemplateCreateFormFields.layoutId: sampleLayout,
};

Widget _templateForm({
  Key? key,
  bool enabled = true,
  Map<String, dynamic>? initialValues,
}) => EvaluationTemplateCreateForm(
  key: key,
  enabled: enabled,
  initialValues: initialValues,
  onEditItem: (_) async => null,
  onEditSectionTitle: (_) async => null,
);

Widget _startForm({Key? key, bool enabled = true, bool fixed = false}) =>
    EvaluationStartForm(
      key: key,
      enabled: enabled,
      templates: _templates,
      members: _members,
      events: _events,
      fixedTemplate: fixed ? _templates.single : null,
      fixedMember: fixed ? _members.single : null,
    );

Widget _itemForm(
  EvaluationItemValue item, {
  Key? key,
  bool enabled = true,
  bool readOnly = false,
}) => EvaluationItemForm(
  key: key,
  kind: item.kind,
  enabled: enabled,
  readOnly: readOnly,
  initialValues: EvaluationItemFormValues.fromItem(item),
);

Future<void> _pump(WidgetTester tester, Widget form) async {
  await tallSurface(tester);
  // A new key each time: a form pumped after another of its type starts
  // afresh.
  await tester.pumpWidget(
    wrapEvaluation(KeyedSubtree(key: UniqueKey(), child: form)),
  );
  await tester.pumpAndSettle();
}

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
  group('Issue 92: a refused template name', () {
    testWidgets('Issue 92: after a "name taken" refusal, a new name '
        'validates and returns the template as a map', (tester) async {
      final key = GlobalKey<EvaluationTemplateCreateFormState>();
      await _pump(
        tester,
        _templateForm(key: key, initialValues: _templateValues()),
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
        ({required on}) =>
            _templateForm(enabled: on, initialValues: _templateValues()),
        ({required on}) => _startForm(enabled: on, fixed: true),
        ({required on}) => EvaluationPeriodForm(enabled: on),
        ({required on}) => _itemForm(qaItem, enabled: on),
      ];
      for (final build in forms) {
        await _pump(tester, build(on: true));
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
        await _pump(tester, build(on: false));
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
      await _pump(tester, _startForm(key: key));
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
      await _pump(tester, _itemForm(multiItem, enabled: false));
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

      await _pump(tester, _itemForm(multiItem, readOnly: true));
      expect(absorbing, findsOneWidget);
    });
  });

  group('Issue 92: saving is not drawn as "may not edit"', () {
    testWidgets('Issue 92: while a template is created, the Sort tick and '
        'the add bar stay on screen, greyed', (tester) async {
      await _pump(
        tester,
        _templateForm(enabled: false, initialValues: _templateValues()),
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
      await _pump(tester, editor(enabled: false));
      expect(find.text('Sort'), findsOneWidget);
      expect(find.byType(EvaluationAddBar), findsWidgets);
      await tester.tap(find.text('Sort'));
      await tester.tap(find.text(qaItem.text));
      await tester.pumpAndSettle();
      expect(find.byIcon(LucideIcons.arrowUp), findsNothing);
      expect(edited, isEmpty);
      expect(emitted, isEmpty);

      await _pump(tester, editor(readOnly: true));
      expect(find.text('Sort'), findsNothing);
      expect(find.byType(EvaluationAddBar), findsNothing);
    });
  });

  group('Issue 92: a refusal shows inside the form', () {
    testWidgets('Issue 92: a refusal of Start review shows inside the '
        'start form and goes on the next validate', (tester) async {
      final key = GlobalKey<EvaluationStartFormState>();
      await _pump(tester, _startForm(key: key, fixed: true));
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
      await _pump(tester, EvaluationPeriodForm(key: key));
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
      await _pump(
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
          _templateForm(initialValues: _templateValues()),
          ['Template name *', 'Items *'],
        ),
        (
          _startForm(),
          ['Template *', 'Member *', 'Event', 'Period from', 'Period to'],
        ),
        (_startForm(fixed: true), ['Template', 'Member', 'Event']),
        (
          const EvaluationPeriodForm(),
          ['Event', 'Period from', 'Period to'],
        ),
        (_itemForm(qaItem), ['Question *']),
        (_itemForm(infoItem), ['Text (markdown) *']),
        (_itemForm(multiItem), ['Question *', 'Choices *']),
        (
          _itemForm(yesNoItem),
          ['Question *', 'Label for Yes', 'Label for No'],
        ),
        (
          _itemForm(levelsItem),
          ['Question *', 'Scale', 'Levels *', 'Require a coach note for'],
        ),
        (
          _itemForm(
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
        await _pump(tester, form);
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
        await _pump(tester, form);
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

      await expectGaps(_templateForm(), ['Template name *', 'Items *']);
      await expectGaps(_startForm(), [
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
      await expectGaps(_itemForm(multiItem), ['Question *', 'Choices *']);
    });
  });
}
