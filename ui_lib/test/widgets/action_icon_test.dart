import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

void main() {
  testWidgets('Issue 263: ActionIcon is announced by its label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var pressed = 0;
    await tester.pumpWidget(
      ShadApp(
        home: Scaffold(
          body: ActionIcon(
            icon: Icons.person_add,
            label: '+ Add user',
            onPressed: () => pressed++,
          ),
        ),
      ),
    );

    final label = find.bySemanticsLabel('+ Add user');
    expect(label, findsOneWidget);
    await tester.tap(label);
    expect(pressed, 1);
    handle.dispose();
  });
}
