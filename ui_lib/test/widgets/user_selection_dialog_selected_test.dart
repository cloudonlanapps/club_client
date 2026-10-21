import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/user_selection_tile.dart'
    show UserSelectionTile;
import 'package:ui_lib/ui_lib.dart';

const alice = PickerUser(username: 'alice', displayName: 'Alice');
const bob = PickerUser(username: 'bob', displayName: 'Bob', isCoach: true);
const carol = PickerUser(username: 'carol', displayName: 'Carol');

/// Opens the picker from a button; the returned list receives its result.
Future<List<List<String>?>> openPicker(WidgetTester tester) async {
  final results = <List<String>?>[];
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ShadButton(
              onPressed: () async => results.add(
                await showUserSelectionDialog(
                  context,
                  title: 'Assign',
                  users: const [alice, bob, carol],
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return results;
}

/// Switches the role filter from Members to Coaches.
Future<void> showCoachesOnly(WidgetTester tester) async {
  await tester.tap(find.text('Filter (1)'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Coaches'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Members'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Filter (1)'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Issue 243: a selected user hidden by the filter is still shown as '
    'selected, can be removed there, and Confirm returns exactly the users '
    'shown as selected',
    (tester) async {
      final results = await openPicker(tester);
      expect(find.text('Selected:'), findsNothing);

      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Carol'));
      await tester.pumpAndSettle();
      await showCoachesOnly(tester);
      expect(find.byType(UserSelectionTile), findsOneWidget);

      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();

      // Alice and Carol are hidden by the filter but named as selected.
      expect(find.text('Selected:'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Carol'), findsOneWidget);
      expect(find.text('Select (3)'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('picker-selected-remove-alice')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Alice'), findsNothing);
      expect(find.text('Select (2)'), findsOneWidget);

      await tester.tap(find.text('Select (2)'));
      await tester.pumpAndSettle();
      expect(results, [
        ['carol', 'bob'],
      ]);
    },
  );
}
