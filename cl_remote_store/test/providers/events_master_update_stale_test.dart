import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

/// Fake [EventSource] for `updateEvent`: an in-memory store whose update
/// either applies (bumping the version) or throws [updateError].
class _FakeEvents extends Fake implements EventSource {
  _FakeEvents(Event seed) {
    store[seed.id] = seed;
  }

  final Map<int, Event> store = {};

  /// When set, `updateEvent` throws this instead of applying.
  Exception? updateError;

  /// The `version` each `updateEvent` call sent.
  final List<int> updateVersions = [];

  int getCalls = 0;

  @override
  Future<PaginatedList<Event>> listEvents({
    DateTime? fromTimeUtc,
    DateTime? toTimeUtc,
    int? venueId,
    EventType? eventType,
    Visibility? visibility,
    int? limit,
    int? offset,
  }) async {
    final items = store.values.toList();
    return PaginatedList<Event>(
      items: items,
      total: items.length,
      offset: 0,
      limit: limit ?? 100,
    );
  }

  @override
  Future<Event> getEvent(int id) async {
    getCalls++;
    return store[id]!;
  }

  @override
  Future<Event> updateEvent(
    int eventId, {
    required int version,
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
    String? Function()? shortDescription,
    String? Function()? stamp,
    List<String>? Function()? highlights,
    List<String>? Function()? includes,
    List<EventSession>? Function()? sessions,
  }) async {
    updateVersions.add(version);
    if (updateError != null) throw updateError!;
    final updated = store[eventId]!.copyWith(
      organizerName: () => organizerName,
      version: version + 1,
    );
    store[eventId] = updated;
    return updated;
  }
}

Event _camp({required int version}) => Event(
  id: 1,
  version: version,
  title: 'workflow_camp',
  description: '',
  type: EventType.camp,
  visibility: Visibility.public,
  venueId: 1,
  startTimeUtc: DateTime.utc(2026, 6),
  endTimeUtc: DateTime.utc(2026, 6, 1, 2),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

void main() {
  group('Issue 110: updateEvent reloads the event on a stale version', () {
    late _FakeEvents fake;
    late ProviderContainer container;

    setUp(() async {
      fake = _FakeEvents(_camp(version: 2));
      container = ProviderContainer(
        overrides: [
          secureClientProvider.overrideWith(
            (ref) async => fakeSecureClient(events: fake),
          ),
        ],
      );
      await container.read(clEventsMasterProvider.future);
    });

    tearDown(() => container.dispose());

    test('Issue 110: a stale version reloads the event and rethrows', () async {
      // Someone else changed the event since it was loaded.
      fake
        ..store[1] = _camp(version: 5)
        ..updateError = StaleVersionException(
          message: 'stale',
          version: 5,
          updatedAtUtc: DateTime.utc(2026, 9, 26, 10),
          updatedBy: 'another_admin',
        );

      await expectLater(
        container
            .read(clEventsMasterProvider.notifier)
            .updateEvent(1, organizerName: 'coach_b'),
        throwsA(isA<StaleVersionException>()),
      );

      expect(fake.updateVersions, [2]);
      expect(fake.getCalls, 1, reason: 'the event is fetched again');
      expect(
        container.read(clEventsMasterProvider).valueOrNull?[1]?.version,
        5,
        reason: 'the cache now holds the version the server has',
      );
    });

    test(
      'Issue 110: a retry after a stale refusal sends the fresh version',
      () async {
        fake
          ..store[1] = _camp(version: 5)
          ..updateError = const StaleVersionException(
            message: 'stale',
            version: 5,
            updatedBy: 'another_admin',
          );
        final notifier = container.read(clEventsMasterProvider.notifier);
        await expectLater(
          notifier.updateEvent(1, organizerName: 'coach_b'),
          throwsA(isA<StaleVersionException>()),
        );

        fake.updateError = null;
        await notifier.updateEvent(1, organizerName: 'coach_b');

        expect(fake.updateVersions, [2, 5]);
      },
    );

    test('Issue 110: any other refusal does not refetch the event', () async {
      fake.updateError = const ServerException(
        statusCode: 404,
        code: SdkErrorCode.userNotFound,
        message: 'Organizer not found',
      );

      await expectLater(
        container
            .read(clEventsMasterProvider.notifier)
            .updateEvent(1, organizerName: 'gone'),
        throwsA(isA<ServerException>()),
      );

      expect(fake.getCalls, 0);
    });
  });
}
