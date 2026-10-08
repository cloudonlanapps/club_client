import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The corner of the screen, on the barrier outside any dialog.
const Offset barrierPoint = Offset(4, 4);

/// The ways a dialog is closed without one of its own buttons, by name.
final Map<String, Future<void> Function(WidgetTester tester)> dismissals = {
  'the close X': (tester) async {
    final icons = find.byIcon(LucideIcons.x);
    for (var i = 0; i < icons.evaluate().length; i++) {
      await tester.tap(icons.at(i), warnIfMissed: false);
    }
  },
  'a tap outside': (tester) => tester.tapAt(barrierPoint),
  'Escape': (tester) => tester.sendKeyEvent(LogicalKeyboardKey.escape),
  'system back': (tester) => tester.binding.handlePopRoute(),
};

/// Tries each of [dismissals] in turn and expects [dialog] to be there
/// after every one (club_client#113).
Future<void> expectNoDismissal(WidgetTester tester, Finder dialog) async {
  for (final MapEntry(key: name, value: dismiss) in dismissals.entries) {
    await dismiss(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(dialog, findsOneWidget, reason: '$name closed the dialog');
  }
}
