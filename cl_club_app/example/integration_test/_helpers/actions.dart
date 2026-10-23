// Finding a header action whatever the screen width.
//
// Owns:
//   * findAction — the action named [label]: an ActionButton on a wide
//                  screen, or the ActionIcon that replaces it on a narrow
//                  one (a phone). Both carry the same label (#263).
//   * pressAction — calls that action's onPressed directly, for flows that
//                  avoid hit-test misses on a narrow viewport.
//   * cardActions — the actions of the cards inside [within]: an ActionGroup
//                  on a wide screen, the first action and an overflow menu
//                  (MobilePrimaryActionRow) on a phone (#291).

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/src/widgets/cards/entity_card.dart'
    show MobilePrimaryActionRow;
import 'package:ui_lib/ui_lib.dart'
    show ActionButton, ActionGroup, ActionIcon, ActionItem;

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

/// The actions of the cards inside [within], in order, whatever the screen
/// width: an [ActionGroup] on a wide screen, a [MobilePrimaryActionRow] (the
/// first action, then the rest in an overflow menu) on a phone.
List<ActionItem> cardActions(WidgetTester tester, Finder within) => [
  for (final g in tester.widgetList<ActionGroup>(
    find.descendant(of: within, matching: find.byType(ActionGroup)),
  ))
    ...g.actions,
  for (final r in tester.widgetList<MobilePrimaryActionRow>(
    find.descendant(of: within, matching: find.byType(MobilePrimaryActionRow)),
  )) ...[r.primary, ...r.overflow],
];
