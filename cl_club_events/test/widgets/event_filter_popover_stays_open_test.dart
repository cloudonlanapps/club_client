import 'package:cl_club_events/src/models/event_filter.dart';
import 'package:cl_club_events/src/widgets/event_filter_popover.dart';
import 'package:club_sdk_2/club_sdk_2.dart' as sdk show Visibility;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  testWidgets('Issue 143: picking a visibility leaves the filter open', (
    tester,
  ) async {
    final emitted = <EventFilter>[];
    await tester.pumpWidget(
      ShadApp(
        home: Scaffold(
          body: Center(
            child: EventFilterPopover(
              initial: const EventFilter(),
              filterByVisibility: true,
              onChanged: emitted.add,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();

    final last = sdk.Visibility.values.last;
    final label = '${last.name[0].toUpperCase()}${last.name.substring(1)}';
    await tester.tap(find.text('All').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();

    expect(emitted.single.visibility, last);
    expect(find.text('Visibility'), findsOneWidget);
    expect(find.text('Include past'), findsOneWidget);
  });
}
