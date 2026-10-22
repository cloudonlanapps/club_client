// Finding a header action whatever the screen width.
//
// Owns:
//   * findAction — the action named [label]: an ActionButton on a wide
//                  screen, or the ActionIcon that replaces it on a narrow
//                  one (a phone). Both carry the same label (#263).
//   * pressAction — calls that action's onPressed directly, for flows that
//                  avoid hit-test misses on a narrow viewport.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton, ActionIcon;

/// The action named [label], as an [ActionButton] or an [ActionIcon].
Finder findAction(String label) => find.byWidgetPredicate(
  (w) =>
      (w is ActionButton && w.label == label) ||
      (w is ActionIcon && w.label == label),
  description: 'action "$label"',
);

/// Calls the `onPressed` of the single action [action] finds.
void pressAction(WidgetTester tester, Finder action) {
  final onPressed = switch (tester.widget(action)) {
    ActionButton(:final onPressed) => onPressed,
    ActionIcon(:final onPressed) => onPressed,
    final Widget other => throw StateError('$other is not an action'),
  };
  if (onPressed == null) throw StateError('$action is disabled');
  onPressed();
}
