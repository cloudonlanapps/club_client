// Issue 67: an evaluation form turned off holds no keyboard focus, so the
// input that had the cursor takes no typing.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/evaluation/common/evaluation_form_focus.dart';
import 'package:ui_lib/src/widgets/evaluation/item_form/evaluation_item_form_fields.dart'
    show EvaluationItemFormFields;
import 'package:ui_lib/ui_lib.dart';

import 'evaluation_test_helpers.dart';

/// Whether the keyboard focus is on a control inside the one form on screen.
bool _focusInForm(WidgetTester tester) {
  final focused = FocusManager.instance.primaryFocus?.context;
  if (focused == null) return false;
  final form = tester.element(find.byType(ShadForm));
  var inside = false;
  focused.visitAncestorElements((element) {
    inside = element == form;
    return !inside;
  });
  return inside;
}

/// The values of the one form on screen.
Map<String, dynamic> _values(WidgetTester tester) => Map<String, dynamic>.of(
  tester.state<ShadFormState>(find.byType(ShadForm)).value,
);

/// Types as the keyboard does, into whatever input holds it.
Future<void> _type(WidgetTester tester) async {
  tester.testTextInput.enterText('typed while off');
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 67: an evaluation form turned off takes no typing', () {
    testWidgets('Issue 67: EvaluationTemplateCreateForm, while the host '
        'creates, takes no typing in the name that had the focus', (
      tester,
    ) async {
      await tallSurface(tester);
      Widget form({required bool enabled}) => wrapEvaluation(
        EvaluationTemplateCreateForm(
          enabled: enabled,
          onEditItem: (_) async => null,
          onEditSectionTitle: (_) async => null,
        ),
      );
      await tester.pumpWidget(form(enabled: true));
      await tester.showKeyboard(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'Skating');
      await tester.pumpAndSettle();
      expect(_focusInForm(tester), isTrue);
      final before = _values(tester);
      expect(before[EvaluationTemplateCreateFormFields.nameId], 'Skating');

      await tester.pumpWidget(form(enabled: false));
      await tester.pumpAndSettle();
      expect(_focusInForm(tester), isFalse);
      await _type(tester);
      expect(_values(tester), before);
    });

    testWidgets('Issue 67: EvaluationItemForm, made read-only, takes no '
        'typing in the question that had the focus', (tester) async {
      await tallSurface(tester);
      Widget form({required bool readOnly}) => wrapEvaluation(
        EvaluationItemForm(
          kind: qaItem.kind,
          initialValues: EvaluationItemFormValues.fromItem(qaItem),
          readOnly: readOnly,
        ),
      );
      await tester.pumpWidget(form(readOnly: false));
      await tester.showKeyboard(find.byType(EditableText).first);
      await tester.pumpAndSettle();
      expect(_focusInForm(tester), isTrue);
      final before = _values(tester);
      expect(before[EvaluationItemFormFields.textId], qaItem.text);

      await tester.pumpWidget(form(readOnly: true));
      await tester.pumpAndSettle();
      expect(_focusInForm(tester), isFalse);
      await _type(tester);
      expect(_values(tester), before);
    });

    testWidgets('Issue 67: EvaluationStartForm, turned off, holds the focus '
        'on none of its selects and dates, and keys change nothing', (
      tester,
    ) async {
      await tallSurface(tester);
      Widget form({required bool enabled}) => wrapEvaluation(
        EvaluationStartForm(
          enabled: enabled,
          templates: const [(id: 1, label: 'Skating')],
          members: const [(username: 'ana', label: 'Ana Rao')],
          events: const [(id: 9, label: 'Spring camp')],
        ),
      );
      await tester.pumpWidget(form(enabled: true));
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsNothing);
      final before = _values(tester);

      var reached = 0;
      for (var stop = 1; stop <= before.length; stop++) {
        await tester.pumpWidget(form(enabled: true));
        await tester.pumpAndSettle();
        for (var i = 0; i < stop; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        }
        await tester.pumpAndSettle();
        if (!_focusInForm(tester)) continue;
        reached++;

        await tester.pumpWidget(form(enabled: false));
        await tester.pumpAndSettle();
        expect(_focusInForm(tester), isFalse, reason: 'stop $stop');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(_values(tester), before, reason: 'stop $stop');
      }
      expect(reached, greaterThan(0), reason: 'controls the focus reached');
    });

    testWidgets('Issue 67: EvaluationPeriodForm has no input to type into, '
        'and drops the focus of a control that is off as the others do', (
      tester,
    ) async {
      await tallSurface(tester);
      final key = GlobalKey<EvaluationPeriodFormState>();
      await tester.pumpWidget(wrapEvaluation(EvaluationPeriodForm(key: key)));
      await tester.pumpAndSettle();

      expect(find.byType(EditableText), findsNothing);
      expect(key.currentState, isA<EvaluationFormFocus>());
    });
  });
}
