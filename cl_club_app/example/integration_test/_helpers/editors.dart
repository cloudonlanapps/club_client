// Section-editor / markdown-editor UI helpers for integration tests.
//
// These drive the shared inline section-editor pattern (see root CLAUDE.md
// "Section-wise Editors"): a section card flips into an inline editor when its
// `SectionEditButton` pencil is tapped, with Save / Cancel rendered in place.
//
// Owns:
//   * tapSectionPencil      — enter inline edit mode for a section card.
//   * expectSectionReadOnly — assert a section exposes no edit affordance.
//   * saveInlineEditor      — invoke inline Save, settle, fast-fail on toast.
//   * cancelInlineEditor    — invoke the inline Cancel.
//   * editMarkdownField     — drive the EditableMarkdown popover editor.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show SectionEditButton;

import 'forms.dart';
import 'pump.dart';

/// Taps the inline edit pencil inside the section [card] (a finder for the
/// card widget), flipping it into inline edit mode. Invokes `onTap` directly
/// so it works regardless of viewport height.
Future<void> tapSectionPencil(WidgetTester tester, Finder card) async {
  final pencil = find.descendant(
    of: card,
    matching: find.byType(SectionEditButton),
  );
  await waitFor(
    tester,
    () => pencil.evaluate().isNotEmpty,
    description: 'edit pencil inside the section card',
  );
  tester.widget<SectionEditButton>(pencil.first).onTap.call();
  await settle(tester);
}

/// Asserts the section [card] exposes no edit affordance — the read-only
/// contract for a viewer without permission.
void expectSectionReadOnly(WidgetTester tester, Finder card) {
  expect(
    find.descendant(of: card, matching: find.byType(SectionEditButton)),
    findsNothing,
    reason: 'section must not show an edit pencil for a read-only viewer',
  );
}

/// Asserts the section [card] exposes at least one edit affordance — the
/// editor's view.
void expectSectionEditable(WidgetTester tester, Finder card) {
  expect(
    find.descendant(of: card, matching: find.byType(SectionEditButton)),
    findsWidgets,
    reason: 'section must show an edit pencil for an editor',
  );
}

/// Invokes the inline editor's Save button, settles, and fast-fails on a
/// destructive toast. The inline editor renders exactly one "Save" while open.
Future<void> saveInlineEditor(WidgetTester tester) async {
  invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Save'),
    reason: 'inline section editor Save',
  );
  await settle(tester);
  await tester.pump(const Duration(seconds: 2));
  await settle(tester);
  final toast = firstErrorToastMessage(tester);
  if (toast != null) {
    throw TestFailure('inline section save failed. Toast: "$toast"');
  }
}

/// Invokes the inline editor's Cancel button.
Future<void> cancelInlineEditor(WidgetTester tester) async {
  invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Cancel'),
    reason: 'inline section editor Cancel',
  );
  await settle(tester);
}

/// The EditableMarkdown editor's own field, by its hint. Other text fields
/// can share the page (a group's "Message this group" composer), so a
/// bare `find.byType(TextField)` may match those instead.
final Finder _markdownEditorField = find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == 'Write markdown here…',
  description: 'EditableMarkdown editor field',
);

/// Opens an `EditableMarkdown` editor (matched by its pencil [tooltip], e.g.
/// 'Edit Bio' / 'Edit Description'), types [markdown], saves, and waits for the
/// editor dialog to close.
Future<void> editMarkdownField(
  WidgetTester tester, {
  required String tooltip,
  required String markdown,
}) async {
  await waitFor(
    tester,
    () => find.byTooltip(tooltip).evaluate().isNotEmpty,
    description: 'markdown pencil with tooltip "$tooltip"',
  );
  await tester.tap(find.byTooltip(tooltip));
  await settle(tester);

  await waitFor(
    tester,
    () => _markdownEditorField.evaluate().isNotEmpty,
    description: 'markdown editor TextField to mount',
  );
  await tester.enterText(_markdownEditorField, markdown);
  await tester.pump();

  invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, 'Save'),
    reason: 'markdown editor Save',
  );
  await settle(tester);
  await waitFor(
    tester,
    () => _markdownEditorField.evaluate().isEmpty,
    description: 'markdown editor dialog to close after Save',
  );
}
