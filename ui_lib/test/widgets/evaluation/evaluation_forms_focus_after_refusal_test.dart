// Issue 93: after a refused save each of evaluation's four forms puts the
// focus where the member has to act, whichever order its host calls
// `showErrors` and turns it on again.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/evaluation/common/evaluation_form_focus.dart';
import 'package:ui_lib/ui_lib.dart';

import 'evaluation_test_helpers.dart';

/// The order in which a host reports a refused save and turns its form on
/// again.
enum _Order { errorsThenOn, errorsFrameThenOn, onThenErrors }

typedef _Case = ({
  String name,
  Widget Function({required bool enabled}) build,
  bool typed,
});

final List<_Case> _cases = [
  (
    name: 'EvaluationTemplateCreateForm',
    build: ({required enabled}) => EvaluationTemplateCreateForm(
      enabled: enabled,
      initialValues: const {
        EvaluationTemplateCreateFormFields.nameId: 'Skating',
        EvaluationTemplateCreateFormFields.layoutId: sampleLayout,
      },
      onEditItem: (_) async => null,
      onEditSectionTitle: (_) async => null,
    ),
    typed: true,
  ),
  (
    name: 'EvaluationStartForm',
    build: ({required enabled}) => EvaluationStartForm(
      enabled: enabled,
      templates: const [(id: 1, label: 'Skating')],
      members: const [(username: 'ana', label: 'Ana Rao')],
      events: const [(id: 9, label: 'Spring camp')],
    ),
    typed: false,
  ),
  (
    name: 'EvaluationPeriodForm',
    build: ({required enabled}) => EvaluationPeriodForm(enabled: enabled),
    typed: false,
  ),
  (
    name: 'EvaluationItemForm',
    build: ({required enabled}) => EvaluationItemForm(
      kind: qaItem.kind,
      enabled: enabled,
      initialValues: EvaluationItemFormValues.fromItem(qaItem),
    ),
    typed: true,
  ),
];

/// A surface short enough that a long form scrolls.
const Size _shortSurface = Size(1024, 420);

/// Plays a refused save on the form [build] gives, in [order], for each
/// field alone, for all at once and for a refusal that names none. Returns
/// how many fields took the focus.
Future<int> _expectFocusAfterRefusal(
  WidgetTester tester,
  Widget Function({required bool enabled}) build,
  _Order order,
) async {
  await tester.binding.setSurfaceSize(_shortSurface);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final enabled = ValueNotifier<bool>(true);
  addTearDown(enabled.dispose);
  await tester.pumpWidget(
    wrapEvaluation(
      ValueListenableBuilder<bool>(
        valueListenable: enabled,
        builder: (context, on, _) => build(enabled: on),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final state = tester.allStates.whereType<EvaluationFormFocus>().first;
  final form = state.formKey.currentState!;
  final ids = form.fields.keys.toList();
  final view = find.byType(SingleChildScrollView).first;
  final scroll = tester.state<ScrollableState>(
    find.descendant(of: view, matching: find.byType(Scrollable)).first,
  );
  final textInputs = find.byType(EditableText);

  Finder fieldWithId(String id) => find.byWidgetPredicate(
    (widget) => widget is ShadFormBuilderField && widget.id == id,
  );

  bool onScreen(Finder finder) =>
      tester.getRect(finder).overlaps(tester.getRect(view));

  Future<void> refuse(
    Map<String, String> fieldErrors, {
    String? formError,
  }) async {
    void show() =>
        state.showErrors(fieldErrors: fieldErrors, formError: formError);
    enabled.value = false;
    await tester.pumpAndSettle();
    expect(form.fields.values.every((f) => !f.enabled), isTrue);
    if (order != _Order.onThenErrors) show();
    if (order == _Order.errorsFrameThenOn) await tester.pump();
    enabled.value = true;
    if (order == _Order.onThenErrors) show();
    await tester.pumpAndSettle();
  }

  bool expectActedOn(String id) {
    final field = form.fields[id]!;
    final node = field.focusNode;
    final typed =
        field.widget is ShadInputFormField ||
        field.widget is ShadTextareaFormField;
    // A field kept out of the focus order (a honeypot) is no input to act on.
    final open = field.enabled && node.canRequestFocus;
    if (typed && open && !field.widget.readOnly) {
      expect(node.hasFocus, isTrue, reason: 'field "$id" has no cursor');
    }
    if (node.context != null && open) {
      expect(node.hasFocus, isTrue, reason: 'field "$id" has no focus');
      return true;
    }
    expect(
      FocusManager.instance.primaryFocus,
      isA<FocusScopeNode>(),
      reason: 'field "$id" has nothing to focus, yet the focus moved',
    );
    final shown = fieldWithId(id);
    if (shown.evaluate().isNotEmpty && !tester.getSize(shown).isEmpty) {
      expect(onScreen(shown), isTrue, reason: 'field "$id" is off screen');
    }
    return false;
  }

  var focused = 0;
  for (final id in ids) {
    final shown = fieldWithId(id);
    scroll.position.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    if (shown.evaluate().isNotEmpty && onScreen(shown)) {
      scroll.position.jumpTo(0);
      await tester.pumpAndSettle();
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await refuse({id: 'Refused by the server.'});
    if (expectActedOn(id)) focused++;
  }

  FocusManager.instance.primaryFocus?.unfocus();
  await refuse({for (final id in ids.reversed) id: 'Refused by the server.'});
  expectActedOn(ids.first);

  const onForm = 'Could not save.';
  final inputs = textInputs.evaluate().length;
  for (var i = 0; i < inputs; i++) {
    await tester.showKeyboard(textInputs.at(i));
    await tester.pumpAndSettle();
    final cursor = tester.widget<EditableText>(textInputs.at(i)).focusNode;
    if (!cursor.hasFocus) continue;
    await refuse(const {}, formError: onForm);
    expect(cursor.hasFocus, isTrue, reason: 'input $i lost the cursor');
  }
  FocusManager.instance.primaryFocus?.unfocus();
  scroll.position.jumpTo(0);
  await refuse(const {}, formError: onForm);
  expect(onScreen(find.text(onForm)), isTrue, reason: 'message off screen');
  return focused;
}

void main() {
  group('Issue 93: after a refused save an evaluation form puts the focus '
      'on the first refused field', () {
    for (final order in _Order.values) {
      for (final c in _cases) {
        testWidgets('Issue 93: ${c.name}, ${order.name}: a refused field '
            'takes the focus or is scrolled into view, and a refusal that '
            'names none gives the cursor back', (tester) async {
          final focused = await _expectFocusAfterRefusal(
            tester,
            c.build,
            order,
          );
          if (c.typed) expect(focused, greaterThan(0), reason: 'focused');
        });
      }
    }
  });
}
