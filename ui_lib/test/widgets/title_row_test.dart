import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/title_row.dart';

void main() {
  testWidgets('Issue 655: TitleRow renders no back button when onBack is '
      'null', (tester) async {
    await tester.pumpWidget(
      const ShadApp(
        home: Scaffold(
          body: TitleRow(title: 'Members'),
        ),
      ),
    );

    expect(find.text('Members'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets(
    'Issue 655: TitleRow renders back button and invokes onBack when provided',
    (tester) async {
      var pressed = 0;
      await tester.pumpWidget(
        ShadApp(
          home: Scaffold(
            body: TitleRow(
              title: 'Event Details',
              onBack: () => pressed++,
            ),
          ),
        ),
      );

      expect(find.text('Event Details'), findsOneWidget);
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pump();
      expect(pressed, 1);
    },
  );

  testWidgets(
    'Issue 207: TitleRow renders no history button when onHistory is null',
    (tester) async {
      await tester.pumpWidget(
        const ShadApp(
          home: Scaffold(
            body: TitleRow(title: 'Members'),
          ),
        ),
      );

      expect(find.byIcon(Icons.history), findsNothing);
    },
  );

  testWidgets(
    'Issue 207: TitleRow renders history button and invokes onHistory',
    (tester) async {
      var pressed = 0;
      await tester.pumpWidget(
        ShadApp(
          home: Scaffold(
            body: TitleRow(
              title: 'Event Details',
              onHistory: () => pressed++,
            ),
          ),
        ),
      );

      final historyButton = find.byIcon(Icons.history);
      expect(historyButton, findsOneWidget);
      // Leading slot still collapsed (no back button supplied).
      expect(find.byIcon(Icons.arrow_back), findsNothing);

      await tester.tap(historyButton);
      await tester.pump();
      expect(pressed, 1);
    },
  );

  testWidgets(
    'Issue 252: TitleRow renders no Broadcast button when onBroadcast is null',
    (tester) async {
      await tester.pumpWidget(
        const ShadApp(
          home: Scaffold(
            body: TitleRow(title: 'Members'),
          ),
        ),
      );

      expect(find.byTooltip('Broadcast'), findsNothing);
      expect(find.byIcon(LucideIcons.messageSquare), findsNothing);
    },
  );

  testWidgets(
    'Issue 252: TitleRow renders the Broadcast button before History and '
    'invokes onBroadcast',
    (tester) async {
      var broadcast = 0;
      var history = 0;
      await tester.pumpWidget(
        ShadApp(
          home: Scaffold(
            body: TitleRow(
              title: 'Juniors',
              onBroadcast: () => broadcast++,
              onHistory: () => history++,
            ),
          ),
        ),
      );

      final broadcastButton = find.byIcon(LucideIcons.messageSquare);
      expect(broadcastButton, findsOneWidget);
      expect(find.byTooltip('Broadcast'), findsOneWidget);
      expect(
        tester.getCenter(broadcastButton).dx,
        lessThan(tester.getCenter(find.byIcon(Icons.history)).dx),
      );

      await tester.tap(broadcastButton);
      await tester.pump();
      expect(broadcast, 1);
      expect(history, 0);
    },
  );
}
