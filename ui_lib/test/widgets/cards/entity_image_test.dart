import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/cards/entity_image.dart';

void main() {
  testWidgets('placeholder renders a ColoredBox', (tester) async {
    await tester.pumpWidget(
      ShadApp(
        home: SizedBox.square(
          dimension: 64,
          child: EntityImage.placeholder(),
        ),
      ),
    );
    // ShadApp adds its own ColoredBox chrome; we only care that ours exists.
    expect(
      find.descendant(
        of: find.byType(EntityImage),
        matching: find.byType(ColoredBox),
      ),
      findsAtLeast(1),
    );
  });

  testWidgets('initials renders the letters', (tester) async {
    await tester.pumpWidget(
      ShadApp(
        home: SizedBox.square(
          dimension: 64,
          child: EntityImage.initials('AS'),
        ),
      ),
    );
    expect(find.text('AS'), findsOneWidget);
  });

  testWidgets('network uses Image widget', (tester) async {
    await tester.pumpWidget(
      ShadApp(
        home: SizedBox.square(
          dimension: 64,
          child: EntityImage.network('https://example.com/img.png'),
        ),
      ),
    );
    expect(find.byType(Image), findsOneWidget);
  });
}
