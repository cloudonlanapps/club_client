import 'package:cl_club_venues/cl_club_venues.dart' show VenueContent;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show MapEmbed, ThemedMarkdown;

const _mapUri = 'https://www.google.com/maps/embed?pb=riverside';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pump();
}

void main() {
  group('Issue 53: VenueContent shows a venue description and map', () {
    testWidgets('Issue 53: renders the description as markdown', (
      tester,
    ) async {
      await _pump(
        tester,
        const VenueContent(description: '**Home ice** of the club'),
      );

      expect(find.byType(ThemedMarkdown), findsOneWidget);
      expect(find.textContaining('Home ice'), findsOneWidget);
      expect(find.textContaining('**'), findsNothing);
      expect(find.byType(MapEmbed), findsNothing);
    });

    testWidgets('Issue 53: renders the location map when there is one', (
      tester,
    ) async {
      await _pump(tester, const VenueContent(mapUri: _mapUri));

      expect(find.text('Location'), findsOneWidget);
      final map = tester.widget<MapEmbed>(find.byType(MapEmbed));
      expect(map.mapUri, _mapUri);
      expect(find.byType(ThemedMarkdown), findsNothing);
    });

    testWidgets('Issue 53: the description is selectable unless the host '
        'says otherwise', (tester) async {
      await _pump(tester, const VenueContent(description: 'About'));
      expect(
        tester.widget<ThemedMarkdown>(find.byType(ThemedMarkdown)).selectable,
        isTrue,
      );

      await _pump(
        tester,
        const VenueContent(description: 'About', selectable: false),
      );
      expect(
        tester.widget<ThemedMarkdown>(find.byType(ThemedMarkdown)).selectable,
        isFalse,
      );
    });
  });
}
