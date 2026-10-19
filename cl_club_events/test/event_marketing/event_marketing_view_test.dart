import 'package:cl_club_events/src/views/event_marketing_view.dart';
import 'package:cl_club_events/src/widgets/event_marketing/event_marketing_preview.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:cl_server_config/cl_server_config.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorView, SectionEditButton;

import '../support/credit_scope.dart';

/// The events master, recording the basic marketing it is asked to write.
class _Events extends StubEvents {
  _Events(super.events);

  final List<Event> written = [];

  @override
  Future<Event> updateBasicMarketing(
    Event event, {
    int? version,
    String? Function()? shortDescription,
    String? Function()? stamp,
    List<String>? Function()? highlights,
    List<String>? Function()? includes,
  }) async {
    final updated = event.copyWith(
      shortDescription: shortDescription,
      stamp: stamp,
      highlights: highlights,
      includes: includes,
    );
    written.add(updated);
    state = AsyncData({...state.value!, event.id: updated});
    return updated;
  }
}

class _Marketing extends ClEventMarketingMasterNotifier {
  _Marketing(this.block);
  final EventMarketing block;
  @override
  Future<EventMarketing> build(int arg) async => block;
}

Future<_Events> _pump(
  WidgetTester tester, {
  required UserPrivate user,
  required bool module,
}) async {
  tester.view.physicalSize = const Size(1400, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final events = _Events({campId: staffed(campId, EventType.camp)});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        serverConfigProvider.overrideWithValue(
          const ServerConfig(baseUrl: 'https://api.example.test/v1'),
        ),
        clEventsMasterProvider.overrideWith(() => events),
        eventMarketingProvider.overrideWithValue(module),
        clEventMarketingMasterProvider.overrideWith(
          () => _Marketing(const EventMarketing(durationText: '5 days')),
        ),
        clPublicSiteMediaProvider.overrideWith((ref, slot) => null),
      ],
      child: ShadApp(
        home: Scaffold(
          body: EventMarketingView(
            currentUser: user,
            eventId: campId,
            onHome: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return events;
}

Finder _inPreview(String text) => find.descendant(
  of: find.byType(EventMarketingPreview),
  matching: find.text(text),
);

void main() {
  final admin = person('an_admin', admin: true);

  group("Issue 1: an event's Marketing page", () {
    testWidgets('Issue 1: without the module only the Basic card shows', (
      tester,
    ) async {
      await _pump(tester, user: admin, module: false);

      expect(find.text('Basic'), findsOneWidget);
      expect(find.text('Details'), findsNothing);
      expect(find.text('Clear extended marketing'), findsNothing);
      expect(find.byType(EventMarketingPreview), findsOneWidget);
    });

    testWidgets('Issue 1: with the module the extended cards show', (
      tester,
    ) async {
      await _pump(tester, user: admin, module: true);

      for (final title in [
        'Basic',
        'Details',
        'Fees',
        'Packages',
        'Offers',
        'Club membership',
        'Facilities',
      ]) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
      expect(find.text('Clear extended marketing'), findsOneWidget);
    });

    testWidgets('Issue 1: what is typed shows in the preview before it is '
        'saved, and goes on Cancel', (tester) async {
      await _pump(tester, user: admin, module: false);
      expect(_inPreview('SOLD OUT'), findsNothing);

      await tester.tap(find.byType(SectionEditButton).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).at(1), 'SOLD OUT');
      await tester.pumpAndSettle();

      expect(_inPreview('SOLD OUT'), findsWidgets);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(_inPreview('SOLD OUT'), findsNothing);
    });

    testWidgets('Issue 1: Save writes the basic block to the event', (
      tester,
    ) async {
      final events = await _pump(tester, user: admin, module: false);

      await tester.tap(find.byType(SectionEditButton).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).at(1), 'NEW');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(events.written.single.stamp, 'NEW');
      expect(_inPreview('NEW'), findsWidgets, reason: 'the saved stamp');
    });

    testWidgets('Issue 1: a coach who is not the organizer is turned away', (
      tester,
    ) async {
      await _pump(tester, user: person(staffCoach, coach: true), module: true);

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Basic'), findsNothing);
    });

    testWidgets('Issue 1: the organizer may edit', (tester) async {
      await _pump(
        tester,
        user: person(staffOrganizer, coach: true),
        module: false,
      );

      expect(find.text('Basic'), findsOneWidget);
    });
  });
}
