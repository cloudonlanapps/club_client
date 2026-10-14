import 'package:cl_member_zone/src/widgets/create_event_quick_action.dart';
import 'package:club_sdk_2/club_sdk_2.dart' show EventType;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Widget _wrap(Set<EventType> types, List<EventType> chosen) => ShadApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 160,
        child: CreateEventQuickAction(
          eventTypes: types,
          onCreateEvent: chosen.add,
        ),
      ),
    ),
  ),
);

void main() {
  group('Issue 115: Create Event follows the club event types', () {
    testWidgets('Issue 115: one type opens its create flow directly', (
      tester,
    ) async {
      final chosen = <EventType>[];
      await tester.pumpWidget(_wrap({EventType.camp}, chosen));

      await tester.tap(find.text('Create Event'));
      await tester.pumpAndSettle();

      expect(chosen, [EventType.camp]);
      expect(find.text('New Camp'), findsNothing);
    });

    testWidgets('Issue 115: several types offer a choice', (tester) async {
      final chosen = <EventType>[];
      await tester.pumpWidget(
        _wrap({EventType.camp, EventType.programme}, chosen),
      );

      await tester.tap(find.text('Create Event'));
      await tester.pumpAndSettle();
      expect(chosen, isEmpty);
      expect(find.text('New Camp'), findsOneWidget);

      await tester.tap(find.text('New Programme'));
      await tester.pumpAndSettle();

      expect(chosen, [EventType.programme]);
      expect(find.text('New Camp'), findsNothing);
    });
  });

  testWidgets('Issue 143: the choice of types is as wide as its entries', (
    tester,
  ) async {
    const tablet = Size(1024, 768);
    await tester.binding.setSurfaceSize(tablet);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _wrap({EventType.camp, EventType.programme, EventType.oneOff}, []),
    );

    await tester.tap(find.text('Create Event'));
    await tester.pumpAndSettle();

    final entries = [
      for (final label in ['New Camp', 'New Programme', 'New One-off'])
        tester.getRect(
          find.ancestor(
            of: find.text(label),
            matching: find.byType(ShadButton),
          ),
        ),
    ];
    for (final entry in entries) {
      expect(entry.width, lessThan(tablet.width / 2));
      expect(entry.width, entries.first.width);
    }
  });
}
