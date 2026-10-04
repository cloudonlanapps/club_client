import 'package:flutter/material.dart' show PopupMenuButton;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/action_button.dart';
import 'package:ui_lib/src/widgets/cards/action_group.dart';
import 'package:ui_lib/src/widgets/cards/action_item.dart';

Future<void> pump(WidgetTester tester, List<ActionItem> actions) {
  return tester.pumpWidget(
    ShadApp(
      home: Center(
        child: ActionGroup(actions: actions),
      ),
    ),
  );
}

void main() {
  testWidgets('empty actions renders nothing visible', (tester) async {
    await pump(tester, []);
    expect(find.byType(ActionButton), findsNothing);
    expect(find.byType(PopupMenuButton<int>), findsNothing);
  });

  testWidgets('one action renders inline, no overflow', (tester) async {
    await pump(tester, [
      ActionItem(label: 'Edit', onPressed: () {}),
    ]);
    expect(find.byType(ActionButton), findsOneWidget);
    expect(find.byType(PopupMenuButton<int>), findsNothing);
    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets('two actions render inline, no overflow', (tester) async {
    await pump(tester, [
      ActionItem(label: 'Edit', onPressed: () {}),
      ActionItem(label: 'Delete', onPressed: () {}),
    ]);
    expect(find.byType(ActionButton), findsNWidgets(2));
    expect(find.byType(PopupMenuButton<int>), findsNothing);
  });

  testWidgets('three actions: 1 inline + 2 in overflow', (tester) async {
    await pump(tester, [
      ActionItem(label: 'Edit', onPressed: () {}),
      ActionItem(label: 'Manage', onPressed: () {}),
      ActionItem(label: 'Delete', onPressed: () {}),
    ]);
    expect(find.byType(ActionButton), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.byType(PopupMenuButton<int>), findsOneWidget);
  });

  testWidgets('four actions: 1 inline + 3 in overflow', (tester) async {
    await pump(tester, [
      ActionItem(label: 'Approve', onPressed: () {}),
      ActionItem(label: 'Block', onPressed: () {}),
      ActionItem(label: 'Reset', onPressed: () {}),
      ActionItem(label: 'Delete', onPressed: () {}),
    ]);
    expect(find.byType(ActionButton), findsOneWidget);
    expect(find.byType(PopupMenuButton<int>), findsOneWidget);
  });

  testWidgets('inlineLimit override changes split', (tester) async {
    await tester.pumpWidget(
      ShadApp(
        home: Center(
          child: ActionGroup(
            inlineLimit: 3,
            actions: [
              ActionItem(label: 'A', onPressed: () {}),
              ActionItem(label: 'B', onPressed: () {}),
              ActionItem(label: 'C', onPressed: () {}),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(ActionButton), findsNWidgets(3));
    expect(find.byType(PopupMenuButton<int>), findsNothing);
  });

  testWidgets('inline action invokes onPressed on tap', (tester) async {
    var taps = 0;
    await pump(tester, [
      ActionItem(label: 'Tap me', onPressed: () => taps++),
    ]);
    await tester.tap(find.text('Tap me'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('loading action does not invoke onPressed', (tester) async {
    var taps = 0;
    await pump(tester, [
      ActionItem(label: 'Wait', onPressed: () => taps++, loading: true),
    ]);
    // Loading ActionButton renders a spinner; `pumpAndSettle` would never
    // settle, so use `tap` + a single `pump` instead.
    await tester.tap(find.byType(ActionButton), warnIfMissed: false);
    await tester.pump();
    expect(taps, 0);
  });

  group('Issue 102: a disabled action shows its reason', () {
    Widget reason(BuildContext context) => const Text('why');

    testWidgets('Issue 102: disabled with a reason shows it beside', (
      tester,
    ) async {
      await pump(tester, [
        ActionItem(label: 'Accept', reason: reason),
      ]);
      expect(find.text('why'), findsOneWidget);
      final button = tester.widget<ActionButton>(find.byType(ActionButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('Issue 102: an enabled action hides its reason', (
      tester,
    ) async {
      await pump(tester, [
        ActionItem(label: 'Accept', onPressed: () {}, reason: reason),
      ]);
      expect(find.text('why'), findsNothing);
    });

    testWidgets('Issue 102: a loading action hides its reason', (
      tester,
    ) async {
      await pump(tester, [
        ActionItem(label: 'Accept', loading: true, reason: reason),
      ]);
      expect(find.text('why'), findsNothing);
    });
  });
}
