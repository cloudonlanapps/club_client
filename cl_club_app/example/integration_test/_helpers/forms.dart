// ShadForm helpers for integration tests.
//
// Owns:
//   * enterTextById          — locate a ShadInputFormField by `id` and type
//                              into its EditableText descendant, typing
//                              again if the field comes back empty. Robust
//                              against form-field reordering across layouts.
//   * ensureTextById         — re-type a field emptied after it was typed.
//   * submitFormContaining   — invoke `onPressed` of the labelled ShadButton
//                              beside the ShadForm enclosing a known field.
//                              Bypasses the gesture system and works for
//                              off-screen submits.
//   * setShadFormValues      — write non-text fields (selects, date pickers)
//                              straight into the ShadForm's value map.
//   * firstErrorToastMessage — pull the description text from the topmost
//                              destructive ShadToast for fast-fail
//                              diagnostics.
//
// Extracted from workflow1.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// How many times [enterTextById] types a value before giving up on a field
/// that keeps coming back empty (club_core#182).
const kEnterTextAttempts = 3;

Future<void> enterTextById(
  WidgetTester tester,
  String fieldId,
  String value,
) async {
  final editable = editableById(tester, fieldId);
  // Now and then a field comes back empty after `enterText` (the login form's
  // username, club_core#182): type again rather than submit a blank. Only an
  // empty field counts as lost; a formatter may rightly change the text.
  for (var attempt = 1; ; attempt++) {
    await tester.enterText(editable, value);
    await tester.pump();
    final kept = textById(tester, fieldId);
    if (value.isEmpty || kept.isNotEmpty) return;
    // Integration test diagnostic output; see loginViaUi.
    // ignore: avoid_print
    print('[test] field "$fieldId" came back empty (attempt $attempt)');
    if (attempt == kEnterTextAttempts) {
      throw TestFailure(
        'field "$fieldId" stayed empty after $attempt attempts to type '
        '${value.length} chars',
      );
    }
  }
}

/// Types [value] into field [fieldId] unless it already holds text, e.g.
/// just before a submit, in case it was emptied after it was typed.
Future<void> ensureTextById(
  WidgetTester tester,
  String fieldId,
  String value,
) async {
  if (textById(tester, fieldId).isNotEmpty || value.isEmpty) return;
  // Integration test diagnostic output; see loginViaUi.
  // ignore: avoid_print
  print('[test] field "$fieldId" was emptied before submit; typing it again');
  await enterTextById(tester, fieldId, value);
}

/// The text field [fieldId] holds now.
String textById(WidgetTester tester, String fieldId) =>
    tester.widget<EditableText>(editableById(tester, fieldId)).controller.text;

/// The EditableText inside the ShadInputFormField with [fieldId].
Finder editableById(WidgetTester tester, String fieldId) {
  final field = find.byWidgetPredicate(
    (w) => w is ShadInputFormField && w.id == fieldId,
  );
  expect(
    field,
    findsOneWidget,
    reason: 'expected ShadInputFormField with id="$fieldId"',
  );
  final editable = find.descendant(
    of: field,
    matching: find.byType(EditableText),
  );
  expect(
    editable,
    findsOneWidget,
    reason: 'expected an EditableText inside field "$fieldId"',
  );
  return editable;
}

/// Submits a ShadForm by invoking `onPressed` of the labelled ShadButton
/// its host draws beside it. The form is identified by a unique-id field
/// it contains.
///
/// Tapping by text proved fragile: `find.widgetWithText` on a generic
/// label like "Sign in" can match the public navbar's button alongside
/// the form's, and even with `.last` the synthesized tap may silently
/// no-op (off-screen, MouseRegion stack). Walking from a known field up
/// to its enclosing ShadForm and on to the button nearest it
/// ([submitButtonBeside]) is unambiguous and screen-size independent.
Future<void> submitFormContaining(
  WidgetTester tester, {
  required String fieldId,
  required String label,
}) async {
  final formFinder = find.ancestor(
    of: find.byWidgetPredicate(
      (w) => w is ShadInputFormField && w.id == fieldId,
    ),
    matching: find.byType(ShadForm),
  );
  expect(
    formFinder,
    findsOneWidget,
    reason: 'expected one ShadForm enclosing field "$fieldId"',
  );
  final btn = submitButtonBeside(formFinder.evaluate().single, label);
  expect(
    btn.onPressed,
    isNotNull,
    reason: '"$label" button should be enabled',
  );
  btn.onPressed!.call();
  await tester.pumpAndSettle(const Duration(milliseconds: 250));
}

/// The ShadButton labelled [label] that belongs to the form at [form]: the
/// one closest to it in the widget tree. A form owns no buttons; its host
/// draws them beside it, so the button and the form share a near ancestor,
/// which a same-labelled button elsewhere on the page (the public navbar's
/// "Sign in") does not.
ShadButton submitButtonBeside(Element form, String label) {
  final around = <Element>[form];
  form.visitAncestorElements((ancestor) {
    around.add(ancestor);
    return true;
  });
  ShadButton? nearest;
  var nearestDistance = around.length;
  for (final candidate in find.widgetWithText(ShadButton, label).evaluate()) {
    var distance = around.length;
    candidate.visitAncestorElements((ancestor) {
      final index = around.indexOf(ancestor);
      if (index < 0) return true;
      distance = index;
      return false;
    });
    if (distance < nearestDistance) {
      nearest = candidate.widget as ShadButton;
      nearestDistance = distance;
    }
  }
  expect(
    nearest,
    isNotNull,
    reason: 'expected a "$label" ShadButton beside the form',
  );
  return nearest!;
}

/// Invokes a ShadButton's `onPressed` directly instead of tapping it.
///
/// Use for buttons that may sit below the test viewport — notably on the
/// 1280x720 Linux desktop window, where form Save / dialog action buttons
/// fall below the fold. A synthesized `tester.tap` resolves to an offset
/// outside the rendered tree and silently no-ops, after which the test
/// times out waiting for state that never changes. Walking the widget tree
/// to invoke `onPressed` sidesteps hit-testing entirely and is screen-size
/// independent.
///
/// Unlike [submitFormContaining], this does not look for the button beside
/// a ShadForm — pass any finder that resolves to a single ShadButton
/// (e.g. `find.widgetWithText(ShadButton, 'Create user')` for a dialog
/// action rendered outside the form).
void invokeShadButton(WidgetTester tester, Finder finder, {String? reason}) {
  expect(finder, findsOneWidget, reason: reason ?? 'expected one ShadButton');
  final btn = tester.widget<ShadButton>(finder);
  expect(
    btn.onPressed,
    isNotNull,
    reason: '${reason ?? 'button'} should be enabled',
  );
  btn.onPressed!.call();
}

/// Writes [values] into the parent ShadForm's value map. ShadFormBuilderField
/// only propagates a value when its custom `setValue(populateForm: true)`
/// runs — the base `FormFieldState.didChange` does not. Writing through the
/// ShadForm state directly is the supported way to set non-text fields
/// (selects, date pickers) in tests.
void setShadFormValues(WidgetTester tester, Map<String, dynamic> values) {
  tester.state<ShadFormState>(find.byType(ShadForm)).setValue(values);
}

/// Returns the description text of the topmost destructive ShadToast, or
/// null if no destructive toast is currently visible. Useful for fast-fail
/// assertions on form submit failures.
String? firstErrorToastMessage(WidgetTester tester) {
  final toasts = find.byType(ShadToast).evaluate();
  for (final el in toasts) {
    final w = el.widget as ShadToast;
    if (w.variant != ShadToastVariant.destructive) continue;
    final desc = w.description;
    if (desc is Text && desc.data != null) return desc.data;
  }
  return null;
}
