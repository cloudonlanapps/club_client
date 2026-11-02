import 'package:flutter/material.dart' show PopupMenuButton;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/action_button.dart';
import 'package:ui_lib/src/widgets/cards/action_group.dart';
import 'package:ui_lib/src/widgets/cards/action_item.dart';
import 'package:ui_lib/src/widgets/cards/entity_card.dart'
    show EntityCard, MobilePrimaryActionRow;
import 'package:ui_lib/src/widgets/cards/entity_image.dart';

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

  group('Issue 143: an action with a popover is reachable from the menu', () {
    final withPopover = ActionItem(
      label: 'Share',
      popover: (context) => const Text('Share content'),
      reason: (context) => const Text('no reason'),
    );

    Future<void> openMenuAndPick(WidgetTester tester, Widget row) async {
      await tester.pumpWidget(ShadApp(home: Center(child: row)));
      await tester.tap(find.byType(PopupMenuButton<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
    }

    test('Issue 143: it is actionable and shows no reason', () {
      expect(withPopover.isActionable, isTrue);
      expect(withPopover.showsReason, isFalse);
    });

    testWidgets('Issue 143: the desktop overflow menu opens it in a dialog', (
      tester,
    ) async {
      await openMenuAndPick(
        tester,
        ActionGroup(
          actions: [
            ActionItem(label: 'Edit', onPressed: () {}),
            ActionItem(label: 'Delete', onPressed: () {}),
            withPopover,
          ],
        ),
      );

      expect(find.byType(ShadDialog), findsOneWidget);
      expect(find.text('Share content'), findsOneWidget);
    });

    testWidgets('Issue 143: the mobile overflow menu opens it in a dialog', (
      tester,
    ) async {
      await openMenuAndPick(
        tester,
        SizedBox(
          width: 360,
          child: MobilePrimaryActionRow(
            primary: ActionItem(label: 'Edit', onPressed: () {}),
            overflow: [withPopover],
          ),
        ),
      );

      expect(find.byType(ShadDialog), findsOneWidget);
      expect(find.text('Share content'), findsOneWidget);
    });
  });

  group('Issue 414: an action draws its leading mark before its label', () {
    const markKey = Key('mark');
    Widget mark(BuildContext _) =>
        const SizedBox(key: markKey, width: 14, height: 14);

    for (final (width, viewport) in [(800.0, 'desktop'), (360.0, 'phone')]) {
      testWidgets('Issue 414: inside the inline button ($viewport)', (
        tester,
      ) async {
        await tester.pumpWidget(
          ShadApp(
            home: Center(
              child: SizedBox(
                width: width,
                child: EntityCard(
                  image: EntityImage.placeholder(),
                  title: 'Morning batch',
                  trailingActions: [
                    ActionItem(
                      label: 'Attendance',
                      leading: mark,
                      onPressed: () {},
                    ),
                    ActionItem(label: 'Reschedule', onPressed: () {}),
                  ],
                ),
              ),
            ),
          ),
        );
        final button = find.ancestor(
          of: find.text('Attendance'),
          matching: find.byType(ShadButton),
        );
        expect(
          find.descendant(of: button, matching: find.byKey(markKey)),
          findsOneWidget,
        );
        expect(
          tester.getRect(find.byKey(markKey)).right,
          lessThanOrEqualTo(tester.getRect(find.text('Attendance')).left),
          reason: 'before the label',
        );
      });
    }

    testWidgets('Issue 414: no mark while the action is loading', (
      tester,
    ) async {
      await pump(tester, [
        ActionItem(label: 'Attendance', leading: mark, loading: true),
      ]);
      expect(find.byKey(markKey), findsNothing);
    });
  });

  group('Issue 414: a disabled action looks disabled', () {
    Future<ShadButton> pumpButton(
      WidgetTester tester,
      VoidCallback? onPressed,
    ) async {
      await tester.pumpWidget(
        ShadApp(
          home: Center(
            child: ActionGroup(
              actions: [
                ActionItem(
                  label: 'Attendance',
                  onPressed: onPressed,
                  reason: (_) => const Text('No members enrolled'),
                ),
              ],
            ),
          ),
        ),
      );
      return tester.widget<ShadButton>(find.byType(ShadButton));
    }

    testWidgets(
      'Issue 414: an action with nothing to do is drawn disabled, its '
      'reason beside it',
      (tester) async {
        final button = await pumpButton(tester, null);
        expect(button.enabled, isFalse);
        expect(find.text('No members enrolled'), findsOneWidget);
      },
    );

    testWidgets('Issue 414: an action that can be used is drawn enabled', (
      tester,
    ) async {
      final button = await pumpButton(tester, () {});
      expect(button.enabled, isTrue);
      expect(find.text('No members enrolled'), findsNothing);
    });
  });
}
