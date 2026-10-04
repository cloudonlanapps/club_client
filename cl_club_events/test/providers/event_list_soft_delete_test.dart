import 'package:cl_club_events/src/models/event_list_filter.dart';
import 'package:cl_club_events/src/providers/event_list.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Event _event(int id, {DateTime? deletedAtUtc}) {
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
    deletedAtUtc: deletedAtUtc,
  );
}

class _StaticCampNotifier extends ClEventsMasterNotifier {
  _StaticCampNotifier(this._events);
  final Map<int, Event> _events;
  @override
  Future<Map<int, Event>> build() async => _events;
}

void main() {
  test(
    'Issue 605: eventListProvider excludes soft-deleted events from active '
    'listings',
    () async {
      final active = _event(1);
      final deleted = _event(2, deletedAtUtc: DateTime.utc(2026, 1, 1));
      final container = ProviderContainer(
        overrides: [
          clEventsMasterProvider.overrideWith(
            () => _StaticCampNotifier({active.id: active, deleted.id: deleted}),
          ),
        ],
      );
      addTearDown(container.dispose);

      // includePast: true so time-based filters don't interfere — the only
      // reason event 2 should be absent is its soft-delete.
      final list = await container.read(
        eventListProvider(const EventListFilter(includePast: true)).future,
      );

      final ids = list.map((e) => e.id).toSet();
      expect(ids, contains(1), reason: 'active event must be listed');
      expect(
        ids,
        isNot(contains(2)),
        reason: 'soft-deleted event must not leak into the active listing',
      );
    },
  );
}
