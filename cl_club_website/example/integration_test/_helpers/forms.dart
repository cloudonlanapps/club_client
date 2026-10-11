// ShadForm helpers for the website's integration tests.
//
// Owns:
//   * enterTextById     - type into the ShadInputFormField with an id,
//                         scrolled into view first.
//   * setShadFormValues - write a non-text field (a select) straight into
//                         the ShadForm's value map.
//   * invokeShadButton  - call a ShadButton's onPressed, on or off screen.
//   * firstErrorToastMessage - the text of the error toast showing, if any.
//
// The same helpers as cl_club_app/example/integration_test/_helpers/forms.dart.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The EditableText inside the ShadInputFormField with [fieldId].
Finder editableById(String fieldId) {
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

/// The text field [fieldId] holds now.
String textById(WidgetTester tester, String fieldId) =>
    tester.widget<EditableText>(editableById(fieldId)).controller.text;

/// Types [value] into field [fieldId]. The page is scrolled to the field
/// first: the test window is 1280x720, and a synthesized `enterText` on a
/// field below the fold silently misses.
Future<void> enterTextById(
  WidgetTester tester,
  String fieldId,
  String value,
) async {
  final editable = editableById(fieldId);
  await Scrollable.ensureVisible(
    tester.element(editable),
    alignment: 0.5,
  );
  await tester.pump();
  await tester.enterText(editable, value);
  await tester.pump();
  expect(textById(tester, fieldId), value, reason: 'field "$fieldId"');
}

/// Writes [values] into the ShadForm's value map: the supported way to set
/// a select in a test, since driving its overlay is fragile.
void setShadFormValues(WidgetTester tester, Map<String, dynamic> values) {
  tester.state<ShadFormState>(find.byType(ShadForm)).setValue(values);
}

/// Calls `onPressed` of the single ShadButton [finder] resolves to. A
/// synthesized tap on a button below the fold lands outside the rendered
/// tree and does nothing; this does not depend on where the button is.
void invokeShadButton(WidgetTester tester, Finder finder, {String? reason}) {
  expect(finder, findsOneWidget, reason: reason ?? 'expected one ShadButton');
  final button = tester.widget<ShadButton>(finder);
  expect(
    button.onPressed,
    isNotNull,
    reason: '${reason ?? 'button'} should be enabled',
  );
  button.onPressed!.call();
}

/// The description of the topmost destructive ShadToast, or null when none
/// is showing.
String? firstErrorToastMessage(WidgetTester tester) {
  for (final element in find.byType(ShadToast).evaluate()) {
    final toast = element.widget as ShadToast;
    if (toast.variant != ShadToastVariant.destructive) continue;
    final description = toast.description;
    if (description is Text && description.data != null) {
      return description.data;
    }
  }
  return null;
}
