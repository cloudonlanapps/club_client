import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/search_input.dart';

void main() {
  testWidgets('search input renders hint', (tester) async {
    await tester.pumpWidget(
      ShadApp(
        home: Scaffold(
          body: SearchInput(
            hint: 'Find users...',
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Find users...'), findsOneWidget);
  });

  testWidgets('debounces input changes', (tester) async {
    String? lastQuery;
    await tester.pumpWidget(
      ShadApp(
        home: Scaffold(
          body: SearchInput(
            debounce: const Duration(milliseconds: 100),
            onChanged: (q) => lastQuery = q,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(ShadInput), 'abc');
    expect(lastQuery, null); // Has not fired yet

    await tester.pump(const Duration(milliseconds: 150));
    expect(lastQuery, 'abc'); // Fired after delay
  });

  testWidgets('clear button resets input', (tester) async {
    String? lastQuery;
    await tester.pumpWidget(
      ShadApp(
        home: Scaffold(
          body: SearchInput(
            debounce: Duration.zero,
            onChanged: (q) => lastQuery = q,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(ShadInput), 'abc');
    await tester.pumpAndSettle();
    expect(lastQuery, 'abc');

    // Tap clear button
    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();

    expect(lastQuery, '');
  });
}
