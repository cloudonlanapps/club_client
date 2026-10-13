import 'dart:async';

import 'package:cl_club_events/src/widgets/event_editor/organizer_coaches_section.dart'
    show OrganizerCoachesSection;
import 'package:cl_club_forms/cl_club_forms.dart' show EventStaffForm;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        ClEventsMasterNotifier,
        ClUsersMasterNotifier,
        clEventsMasterProvider,
        clUsersMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

final Event _event = Event(
  id: 1,
  version: 4,
  title: 'workflow_staff',
  description: '',
  type: EventType.camp,
  visibility: Visibility.public,
  venueId: 7,
  startTimeUtc: DateTime.utc(2026, 6, 15, 6),
  endTimeUtc: DateTime.utc(2026, 6, 15, 8),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
  organizerName: 'org',
  coachNames: const ['coach_a'],
);

/// Holds every update until [answer] completes, then refuses it.
class _HeldEvents extends ClEventsMasterNotifier {
  final Completer<void> answer = Completer<void>();

  @override
  Future<Map<int, Event>> build() async => {_event.id: _event};

  @override
  Future<Event> updateEvent(
    int eventId, {
    int? version,
    String? title,
    String? description,
    Visibility? visibility,
    String? organizerName,
    List<String>? Function()? coachNames,
    Gender? Function()? gender,
    Age? Function()? minAge,
    Age? Function()? maxAge,
    bool? strictAge,
    bool? isFeatured,
    List<String>? Function()? galleryUris,
    List<EventSession>? Function()? sessions,
  }) async {
    await answer.future;
    throw const ServerException(
      statusCode: 500,
      code: 'INTERNAL',
      message: 'raw server text',
    );
  }
}

class _NoUsers extends ClUsersMasterNotifier {
  @override
  Future<Map<String, UserInfo>> build() async => {};
}

bool _formOn(WidgetTester tester) =>
    tester.widget<EventStaffForm>(find.byType(EventStaffForm)).enabled;

void main() {
  testWidgets('Issue 91: the Organizer & Coaches form is off while its save '
      'is in flight, and on again once it is refused', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final events = _HeldEvents();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clEventsMasterProvider.overrideWith(() => events),
          clUsersMasterProvider.overrideWith(_NoUsers.new),
        ],
        child: ShadApp(
          home: ShadToaster(
            child: Scaffold(
              body: SingleChildScrollView(
                child: OrganizerCoachesSection(event: _event),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.pencil));
    await tester.pumpAndSettle();
    // Removes the one coach, so there is something to save.
    await tester.tap(find.widgetWithIcon(ShadButton, LucideIcons.x));
    await tester.pumpAndSettle();
    expect(_formOn(tester), isTrue);

    await tester.tap(find.widgetWithText(ShadButton, 'Save'));
    await tester.pump();
    expect(_formOn(tester), isFalse);

    events.answer.complete();
    await tester.pumpAndSettle();
    expect(_formOn(tester), isTrue);
  });
}
