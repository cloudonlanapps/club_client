// The moves of the application editor's heading card (club_client#398).
//
// Owns:
//   * applicationStep — the move named [name] (`save`, `publish`, `revert`,
//                       `unpublish`, `delete`), shown only in the states
//                       that allow it.
//   * applicationStepEnabled — whether that move is shown and on: Delete is
//                       a bin icon (ShadIconButton), every other move an
//                       ActionButton.
//   * runApplicationStep — waits for the move to be on, then presses it.
//   * pdfActionButtonIn — the PDF button (Download or Share, as the app
//                       chose for the platform) inside a scope.

import 'package:cl_club_app/src/utils/pdf_actions.dart' show appPdfAction;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadButton, ShadIconButton;
import 'package:ui_lib/ui_lib.dart' show ActionButton;

import 'pump.dart';

/// The move of the heading card named [name] (`save` is Finalize).
Finder applicationStep(String name) =>
    find.byKey(ValueKey('application.step.$name'));

/// Whether the move [name] is shown and may run now.
bool applicationStepEnabled(WidgetTester tester, String name) {
  final step = applicationStep(name);
  if (step.evaluate().isEmpty) return false;
  return switch (tester.widget(step)) {
    final ActionButton button => button.enabled,
    final ShadIconButton icon => icon.enabled,
    final other => throw StateError('unexpected move widget $other'),
  };
}

/// Waits for the move [name] to be shown and on, then presses it.
Future<void> runApplicationStep(WidgetTester tester, String name) async {
  await waitFor(
    tester,
    () => applicationStepEnabled(tester, name),
    description: 'the "$name" step to be enabled',
  );
  final onPressed = switch (tester.widget(applicationStep(name))) {
    final ActionButton button => button.onPressed,
    final ShadIconButton icon => icon.onPressed,
    final other => throw StateError('unexpected move widget $other'),
  };
  onPressed!();
  await settle(tester);
}

/// The PDF button inside [scope], by the label of the app's own
/// [appPdfAction]: Share on a phone browser that can share files,
/// Download elsewhere (club_client#324).
Finder pdfActionButtonIn(Finder scope) => find.descendant(
  of: scope,
  matching: find.widgetWithText(ShadButton, appPdfAction.label),
);
