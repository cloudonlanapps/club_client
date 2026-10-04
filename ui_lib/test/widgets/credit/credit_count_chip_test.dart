import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

Future<void> _pump(WidgetTester tester, Widget chip) => tester.pumpWidget(
  ShadApp(home: Center(child: chip)),
);

void main() {
  group('Issue 102: CreditCountChip', () {
    testWidgets('Issue 102: shows the coin and the number, and taps', (
      tester,
    ) async {
      var taps = 0;
      await _pump(tester, CreditCountChip(credits: 12, onTap: () => taps++));

      expect(find.text('12'), findsOneWidget);
      expect(find.byIcon(LucideIcons.coins), findsOneWidget);
      expect(find.bySemanticsLabel('Credit 12'), findsOneWidget);

      await tester.tap(find.byType(CreditCountChip));
      expect(taps, 1);
    });

    testWidgets('Issue 105: the add form shows a plus, not a number', (
      tester,
    ) async {
      await _pump(tester, CreditCountChip(add: true, onTap: () {}));

      expect(find.byIcon(LucideIcons.plus), findsOneWidget);
      expect(find.bySemanticsLabel('Add credit'), findsOneWidget);
    });
  });
}
