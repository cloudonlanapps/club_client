import 'package:cl_club_events/src/models/event_list_filter.dart';
import 'package:cl_club_events/src/providers/event_list.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Event _event(int id, {bool archived = false}) {
  final now = DateTime.now().toUtc();
  return Event(
    id: id,
    title: 'workflow_camp_$id',
    description: '',
    type: EventType.camp,
    visibility: Visibility.public,
    venueId: 1,
    startTimeUtc: now,
    endTimeUtc: now.add(const Duration(hours: 1)),
    createdAtUtc: now,
    updatedAtUtc: now,
    deletedAtUtc: archived ? DateTime.utc(2026) : null,
  );
}

class _StaticEvents extends ClEventsMasterNotifier {
  _StaticEvents(this.events);
  final Map<int, Event> events;
  @override
  Future<Map<int, Event>> build() async => events;
}

Future<Set<int>> _listed(EventListFilter filter) async {
  final container = ProviderContainer(
    overrides: [
      clEventsMasterProvider.overrideWith(
        () => _StaticEvents({1: _event(1), 2: _event(2, archived: true)}),
      ),
    ],
  );
  addTearDown(container.dispose);
  final list = await container.read(eventListProvider(filter).future);
  return list.map((e) => e.id).toSet();
}

void main() {
  group('Issue 36: the event list and archived events', () {
    test('Issue 36: archived events are left out by default', () async {
      expect(await _listed(const EventListFilter(includePast: true)), {1});
    });

    test('Issue 36: Show archived lists them with the live ones', () async {
      expect(
        await _listed(
          const EventListFilter(includePast: true, showArchived: true),
        ),
        {1, 2},
      );
    });

    test('Issue 36: the filter value carries showArchived', () {
      const base = EventListFilter();
      expect(base.showArchived, isFalse);
      expect(base.copyWith(showArchived: true).showArchived, isTrue);
      expect(base.copyWith(showArchived: true), isNot(base));
    });
  });
}
