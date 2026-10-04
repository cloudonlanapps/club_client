import 'package:flutter/material.dart' show Card;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/status_badge.dart';

void main() {
  testWidgets('renders active label via factory', (tester) async {
    await tester.pumpWidget(
      ShadApp(home: SizedBox(child: StatusBadge.active())),
    );
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('renders blocked label via factory', (tester) async {
    await tester.pumpWidget(
      ShadApp(home: SizedBox(child: StatusBadge.blocked())),
    );
    expect(find.text('Blocked'), findsOneWidget);
  });

  testWidgets('renders dynamic status via .status()', (tester) async {
    await tester.pumpWidget(
      ShadApp(home: SizedBox(child: StatusBadge.status('unknown'))),
    );
    expect(find.text('unknown'), findsOneWidget);
  });

  testWidgets('renders pending status via .status()', (tester) async {
    await tester.pumpWidget(
      ShadApp(home: SizedBox(child: StatusBadge.status('pending'))),
    );
    expect(find.text('pending'), findsOneWidget);
  });

  testWidgets('has a bordered Container, no Material/Card', (tester) async {
    await tester.pumpWidget(
      ShadApp(home: SizedBox(child: StatusBadge.active())),
    );
    // No Material Card chrome — bordered chip is a plain Container.
    expect(find.byType(Card), findsNothing);
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(StatusBadge),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.border, isNotNull);
    // No filled background — only an outlined border.
    expect(decoration.color, isNull);
  });
}
