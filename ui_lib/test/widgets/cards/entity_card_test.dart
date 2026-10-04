import 'package:flutter/material.dart' show Card, InkWell, ListTile, Material;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/cards/action_item.dart';
import 'package:ui_lib/src/widgets/cards/entity_card.dart';
import 'package:ui_lib/src/widgets/cards/entity_image.dart';

Future<void> pump(WidgetTester tester, EntityCard card) {
  return tester.pumpWidget(
    ShadApp(
      home: Center(
        child: SizedBox(width: 400, child: card),
      ),
    ),
  );
}

void main() {
  testWidgets('renders title; image always present', (tester) async {
    await pump(
      tester,
      EntityCard(
        image: EntityImage.placeholder(),
        title: 'Hello',
      ),
    );
    expect(find.text('Hello'), findsOneWidget);
    expect(find.byType(EntityImage), findsOneWidget);
  });

  testWidgets('renders caption + body when provided', (tester) async {
    await pump(
      tester,
      EntityCard(
        image: EntityImage.placeholder(),
        title: 'Title',
        caption: 'Caption line',
        body: const Text('Body text'),
      ),
    );
    expect(find.text('Caption line'), findsOneWidget);
    expect(find.text('Body text'), findsOneWidget);
  });

  testWidgets('tap invokes onTap', (tester) async {
    var tapped = 0;
    await pump(
      tester,
      EntityCard(
        image: EntityImage.placeholder(),
        title: 'Tap me',
        onTap: () => tapped++,
      ),
    );
    await tester.tap(find.text('Tap me'));
    await tester.pumpAndSettle();
    expect(tapped, 1);
  });

  testWidgets('no onTap → no tap target', (tester) async {
    await pump(
      tester,
      EntityCard(
        image: EntityImage.placeholder(),
        title: 'No tap',
      ),
    );
    // GestureDetector is only inserted when onTap != null.
    expect(find.byType(GestureDetector), findsNothing);
  });

  testWidgets('does not use Material widgets', (tester) async {
    await pump(
      tester,
      EntityCard(
        image: EntityImage.placeholder(),
        title: 'No material',
        onTap: () {},
      ),
    );
    expect(find.byType(InkWell), findsNothing);
    expect(find.byType(ListTile), findsNothing);
    expect(find.byType(Card), findsNothing);
    // Material can appear from underlying ShadApp scaffolding; only our own
    // tree must avoid it. Restrict the search to descendants of EntityCard.
    expect(
      find.descendant(
        of: find.byType(EntityCard),
        matching: find.byType(Material),
      ),
      findsNothing,
    );
  });

  testWidgets('dense reduces padding and shrinks title', (tester) async {
    await pump(
      tester,
      EntityCard(
        image: EntityImage.placeholder(),
        title: 'Dense',
        dense: true,
      ),
    );
    final text = tester.widget<Text>(find.text('Dense'));
    expect(text.style?.fontSize, 13);
  });

  Future<void> pumpAtWidth(
    WidgetTester tester,
    double width,
    EntityCard card,
  ) {
    return tester.pumpWidget(
      ShadApp(
        home: Center(
          child: SizedBox(width: width, child: card),
        ),
      ),
    );
  }

  testWidgets(
    'Issue 493: at 360px width, ActionGroup-shaped trailing stacks below '
    'instead of overflowing',
    (tester) async {
      final originalOnError = FlutterError.onError;
      final errors = <FlutterErrorDetails>[];
      FlutterError.onError = errors.add;
      try {
        await pumpAtWidth(
          tester,
          360,
          EntityCard(
            image: EntityImage.placeholder(),
            title: 'Senior Boys with a long enough title to stress layout',
            body: const Text('DOB ≤ 2008-05-14 · Semi-auto · members 42'),
            trailingAction: const SizedBox(
              width: 140,
              height: 32,
              child: Center(child: Text('[Edit] [Delete]')),
            ),
          ),
        );
        await tester.pump();
        final overflow = errors.where(
          (e) => e.toString().toLowerCase().contains('overflow'),
        );
        expect(
          overflow,
          isEmpty,
          reason: 'No render overflow expected at mobile width.',
        );
      } finally {
        FlutterError.onError = originalOnError;
      }
    },
  );

  testWidgets(
    'Issue 489: typed trailingActions on desktop render an ActionGroup',
    (tester) async {
      await pumpAtWidth(
        tester,
        800,
        EntityCard(
          image: EntityImage.placeholder(),
          title: 'Desktop',
          trailingActions: [
            ActionItem(label: 'Edit', onPressed: () {}),
            ActionItem(label: 'Delete', destructive: true, onPressed: () {}),
          ],
        ),
      );
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 489: typed trailingActions on mobile expose primary inline + '
    'overflow menu for secondaries',
    (tester) async {
      await pumpAtWidth(
        tester,
        360,
        EntityCard(
          image: EntityImage.placeholder(),
          title: 'Mobile',
          trailingActions: [
            ActionItem(label: 'Edit', onPressed: () {}),
            ActionItem(label: 'Delete', destructive: true, onPressed: () {}),
          ],
        ),
      );
      // Primary action label is visible inline.
      expect(find.text('Edit'), findsOneWidget);
      // Secondaries sit behind the ⋮ menu when there are 2+ actions.
      expect(find.byIcon(LucideIcons.ellipsisVertical), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 64: on mobile, secondaries live only in the overflow menu — '
    'a swipe on the card reveals nothing',
    (tester) async {
      await pumpAtWidth(
        tester,
        360,
        EntityCard(
          image: EntityImage.placeholder(),
          title: 'Mobile',
          trailingActions: [
            ActionItem(label: 'Edit', onPressed: () {}),
            ActionItem(label: 'Delete', destructive: true, onPressed: () {}),
          ],
        ),
      );
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsNothing);

      await tester.drag(find.text('Mobile'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(
        find.text('Delete'),
        findsNothing,
        reason: 'A swipe must not reveal a second home for secondaries.',
      );

      await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 489: single typed action on mobile has no overflow menu',
    (tester) async {
      await pumpAtWidth(
        tester,
        360,
        EntityCard(
          image: EntityImage.placeholder(),
          title: 'Only one',
          trailingActions: [
            ActionItem(label: 'Edit', onPressed: () {}),
          ],
        ),
      );
      expect(find.text('Edit'), findsOneWidget);
      expect(find.byIcon(LucideIcons.ellipsisVertical), findsNothing);
    },
  );

  testWidgets(
    'Issue 489: trailingAction and trailingActions are mutually exclusive',
    (tester) async {
      expect(
        () => EntityCard(
          image: EntityImage.placeholder(),
          title: 'Bad',
          trailingAction: const SizedBox.shrink(),
          trailingActions: [ActionItem(label: 'X', onPressed: () {})],
        ),
        throwsAssertionError,
      );
    },
  );

  testWidgets('muted uses mutedForeground on title', (tester) async {
    late ShadThemeData captured;
    await tester.pumpWidget(
      ShadApp(
        home: Builder(
          builder: (context) {
            captured = ShadTheme.of(context);
            return Center(
              child: SizedBox(
                width: 400,
                child: EntityCard(
                  image: EntityImage.placeholder(),
                  title: 'Muted',
                  muted: true,
                ),
              ),
            );
          },
        ),
      ),
    );
    final text = tester.widget<Text>(find.text('Muted'));
    expect(text.style?.color, captured.colorScheme.mutedForeground);
  });
}
