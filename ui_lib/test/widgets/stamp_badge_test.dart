import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

void main() {
  testWidgets('Issue 47: StampBadge is exported and renders its text', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ShadApp(
        home: Scaffold(body: StampBadge(text: 'new')),
      ),
    );

    expect(find.text('NEW'), findsOneWidget);
  });
}
