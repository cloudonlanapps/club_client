import 'package:cl_club_events/src/models/event_filter.dart';
import 'package:cl_club_events/src/widgets/event_filter_popover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Future<List<EventFilter>> _open(
  WidgetTester tester, {
  required bool showArchivedToggle,
}) async {
  final emitted = <EventFilter>[];
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: Center(
          child: EventFilterPopover(
            initial: const EventFilter(),
            showArchivedToggle: showArchivedToggle,
            onChanged: emitted.add,
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Filter'));
  await tester.pumpAndSettle();
  return emitted;
}

void main() {
  group('Issue 36: the Show archived switch of the event filter', () {
    testWidgets('Issue 36: it is offered when the list asks for it', (
      tester,
    ) async {
      await _open(tester, showArchivedToggle: true);
      expect(find.text(EventFilterPopover.showArchivedLabel), findsOneWidget);
    });

    testWidgets('Issue 36: it is absent otherwise', (tester) async {
      await _open(tester, showArchivedToggle: false);
      expect(find.text('Include past'), findsOneWidget);
      expect(find.text(EventFilterPopover.showArchivedLabel), findsNothing);
    });

    testWidgets('Issue 36: turning it on emits showArchived', (tester) async {
      final emitted = await _open(tester, showArchivedToggle: true);

      await tester.tap(find.byType(ShadSwitch).last);
      await tester.pumpAndSettle();

      expect(emitted.single.showArchived, isTrue);
      expect(emitted.single.includePast, isTrue);
    });
  });
}
