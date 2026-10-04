import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/pagination_bar.dart';

void main() {
  testWidgets('displays correct text for page 1', (tester) async {
    await tester.pumpWidget(
      const ShadApp(
        home: Scaffold(
          body: PaginationBar(
            total: 156,
            limit: 20,
            offset: 0,
          ),
        ),
      ),
    );
    expect(find.text('Showing 1–20 of 156'), findsOneWidget);
  });

  testWidgets('displays correct text for last page', (tester) async {
    await tester.pumpWidget(
      const ShadApp(
        home: Scaffold(
          body: PaginationBar(
            total: 156,
            limit: 20,
            offset: 140,
          ),
        ),
      ),
    );
    expect(find.text('Showing 141–156 of 156'), findsOneWidget);
  });

  testWidgets('displays correct text for empty results', (tester) async {
    await tester.pumpWidget(
      const ShadApp(
        home: Scaffold(
          body: PaginationBar(
            total: 0,
            limit: 20,
            offset: 0,
          ),
        ),
      ),
    );
    expect(find.text('Showing 0–0 of 0'), findsOneWidget);
  });

  testWidgets('buttons disabled appropriately', (tester) async {
    var nextCalled = false;
    var prevCalled = false;

    await tester.pumpWidget(
      ShadApp(
        home: Scaffold(
          body: PaginationBar(
            total: 15,
            limit: 20,
            offset: 0,
            onNext: () => nextCalled = true,
            onPrevious: () => prevCalled = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Next'));
    await tester.pump();
    expect(nextCalled, false); // Disabled because all items fit on first page

    await tester.tap(find.text('Previous'));
    await tester.pump();
    expect(prevCalled, false); // Disabled because offset is 0
  });
}
