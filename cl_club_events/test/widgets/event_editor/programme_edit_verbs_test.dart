// A programme is corrected, never updated: the server offers `updateEvent`
// to camps and one-offs only (club_client#118).
import 'package:cl_club_events/src/widgets/event_editor/editable_event_body.dart'
    show EventFlagsCard;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier, clEventsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Event _event(EventType type) => Event(
  id: 1,
  version: 4,
  title: 'Skating',
  description: '',
  type: type,
  visibility: Visibility.public,
  venueId: 7,
  startTimeUtc: DateTime.utc(2026, 6, 15, 6),
  endTimeUtc: DateTime.utc(2026, 6, 15, 8),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

/// Records which call each flag write went through, and what it carried.
class _RecordingEvents extends ClEventsMasterNotifier {
  _RecordingEvents(this.event);

  final Event event;
  final List<(String verb, Visibility? visibility, bool? isFeatured)> sent = [];

  @override
  Future<Map<int, Event>> build() async => {event.id: event};

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
    sent.add(('update', visibility, isFeatured));
    return event;
  }

  @override
  Future<Event> correctionOnEvent(
    int eventId, {
    int? version,
    String? title,
    String? description,
    Visibility? visibility,
    Gender? Function()? gender,
    Age? Function()? minAge,
    Age? Function()? maxAge,
    bool? strictAge,
    bool? isFeatured,
    List<String>? Function()? galleryUris,
    List<EventSession>? Function()? sessions,
    int? scheduleId,
  }) async {
    sent.add(('correction', visibility, isFeatured));
    return event;
  }
}

Future<_RecordingEvents> _pump(WidgetTester tester, Event event) async {
  final events = _RecordingEvents(event);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [clEventsMasterProvider.overrideWith(() => events)],
      child: ShadApp(
        home: Scaffold(body: EventFlagsCard(event: event)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return events;
}

void main() {
  testWidgets("Issue 118: a programme's Featured switch is saved as a "
      'correction', (tester) async {
    final events = await _pump(tester, _event(EventType.programme));

    await tester.tap(find.text('This event is featured'));
    await tester.pumpAndSettle();

    expect(events.sent, [('correction', null, true)]);
  });

  testWidgets("Issue 118: a programme's Private switch is saved as a "
      'correction', (tester) async {
    final events = await _pump(tester, _event(EventType.programme));

    await tester.tap(find.text('This is a private event'));
    await tester.pumpAndSettle();

    expect(events.sent, [('correction', Visibility.private, null)]);
  });

  testWidgets("Issue 118: a camp's Featured switch is saved as an update", (
    tester,
  ) async {
    final events = await _pump(tester, _event(EventType.camp));

    await tester.tap(find.text('This event is featured'));
    await tester.pumpAndSettle();

    expect(events.sent, [('update', null, true)]);
  });
}
