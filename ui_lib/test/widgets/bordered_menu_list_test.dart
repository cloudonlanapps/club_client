import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/bordered_menu_list.dart'
    show BorderedMenuList;
import 'package:ui_lib/ui_lib.dart';

void main() {
  testWidgets('Issue 47: renders the title and every item', (tester) async {
    await tester.pumpWidget(
      ShadApp(
        home: Scaffold(
          body: BorderedMenuList(
            title: 'Section',
            items: [
              BorderedMenuItem(label: 'First', onTap: () {}),
              BorderedMenuItem(label: 'Second', onTap: () {}),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Section'), findsOneWidget);
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
  });

  testWidgets('Issue 47: tapping an item calls its onTap', (tester) async {
    final tapped = <String>[];
    await tester.pumpWidget(
      ShadApp(
        home: Scaffold(
          body: BorderedMenuList(
            items: [
              BorderedMenuItem(label: 'First', onTap: () => tapped.add('1')),
              BorderedMenuItem(label: 'Second', onTap: () => tapped.add('2')),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Second'));
    expect(tapped, ['2']);
  });
}
