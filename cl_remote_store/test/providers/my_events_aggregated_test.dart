import 'dart:async';

import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

const _member = 'alice';
const _eventCount = 5;

Event _event(int id) => Event(
  id: id,
  title: 'Event $id',
  description: '',
  type: EventType.camp,
  visibility: Visibility.public,
  venueId: 1,
  startTimeUtc: DateTime.utc(2026, 11, id),
  endTimeUtc: DateTime.utc(2026, 11, id, 2),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

/// Lists [_eventCount] events; each enrolment read waits on [gate].
class _MyEvents extends Fake implements MyEventsSource {
  final gate = Completer<void>();
  int started = 0;
  int completed = 0;

  @override
  Future<PaginatedList<Event>> listMyEvents(
    String username, {
    DateTime? fromTimeUtc,
    DateTime? toTimeUtc,
    int? offset,
    int? limit,
  }) async {
    final items = [for (var id = _eventCount; id >= 1; id--) _event(id)];
    return PaginatedList(
      items: (offset ?? 0) == 0 ? items : const [],
      total: items.length,
      offset: offset ?? 0,
      limit: limit ?? 20,
    );
  }

  @override
  Future<Enrollment> getMyEnrollment(String username, int eventId) async {
    started++;
    await gate.future;
    completed++;
    return Enrollment(
      id: eventId,
      membername: username,
      eventId: eventId,
      status: EnrollmentStatus.assigned,
      createdAtUtc: DateTime.utc(2026),
    );
  }
}

void main() {
  test(
    'Issue 237: with N events, the enrolment fetches start before any '
    'completes, and each event carries its enrolment',
    () async {
      final myEvents = _MyEvents();
      final container = ProviderContainer(
        overrides: [
          secureClientProvider.overrideWith(
            (ref) async => fakeSecureClient(myEvents: myEvents),
          ),
        ],
      );
      addTearDown(container.dispose);
      final provider = clMyEventsAggregatedProvider(_member);
      final sub = container.listen(provider, (_, _) {});
      addTearDown(sub.close);

      // Wait (bounded) until the enrolment reads have started.
      for (var i = 0; i < 50 && myEvents.started < _eventCount; i++) {
        await pumpEventQueue();
      }
      expect(myEvents.started, _eventCount);
      expect(myEvents.completed, 0);

      myEvents.gate.complete();
      final aggregated = await container.read(provider.future);

      expect(aggregated.map((a) => a.event.id), [1, 2, 3, 4, 5]);
      expect(
        aggregated.map((a) => a.enrollment?.eventId),
        [1, 2, 3, 4, 5],
      );
    },
  );
}
