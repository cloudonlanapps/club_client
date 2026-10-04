import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

/// Fake [VenueSource] backed by an in-memory store. Models the server's
/// soft-delete semantics: `deleteVenue` sets `deletedAtUtc` (the row
/// survives) and echoes the soft-deleted venue, while `getVenues` (the
/// active listing) excludes soft-deleted rows.
class _FakeVenues extends Fake implements VenueSource {
  _FakeVenues(Iterable<Venue> seed) {
    for (final v in seed) {
      store[v.id] = v;
    }
  }

  final Map<int, Venue> store = {};

  /// When set, `deleteVenue` throws this instead of soft-deleting — models
  /// the server rejecting the delete (e.g. VENUE_HAS_EVENTS).
  Exception? deleteError;

  int deleteCalls = 0;

  @override
  Future<PaginatedList<Venue>> getVenues({
    int offset = 0,
    int limit = 20,
  }) async {
    final active = store.values.where((v) => v.isActive).toList();
    return PaginatedList<Venue>(
      items: active,
      total: active.length,
      offset: 0,
      limit: limit,
    );
  }

  @override
  Future<Venue> deleteVenue(int id) async {
    deleteCalls++;
    if (deleteError != null) {
      throw deleteError!;
    }
    final deleted = store[id]!.copyWith(
      deletedAtUtc: () => DateTime.utc(2026, 1, 1),
    );
    store[id] = deleted;
    return deleted;
  }
}

SecureClient _buildClient(VenueSource venues) {
  return fakeSecureClient(
    venues: venues,
  );
}

ProviderContainer _makeContainer(VenueSource venues) {
  return ProviderContainer(
    overrides: [
      secureClientProvider.overrideWith((ref) async => _buildClient(venues)),
    ],
  );
}

Venue _venue(int id, {String name = 'workflow_venue_site'}) => Venue(
  id: id,
  name: name,
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

void main() {
  test(
    'Issue 509: deleteVenue reflects the server round-trip — the venue stays '
    'in the master map with isActive == false (not silently removed)',
    () async {
      final fake = _FakeVenues([_venue(1)]);
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      final loaded = await container.read(clVenuesMasterProvider.future);
      expect(loaded[1]?.isActive, isTrue, reason: 'seeded venue is active');

      await container.read(clVenuesMasterProvider.notifier).deleteVenue(1);

      final after = container.read(clVenuesMasterProvider).valueOrNull;
      expect(after, isNotNull);
      // The notifier must store the soft-deleted entity echoed by the server
      // so the in-memory map mirrors real server state, rather than blindly
      // dropping the id (which would pass an `isActive == false` assertion
      // even when the server delete never persisted).
      expect(
        after![1],
        isNotNull,
        reason: 'soft-deleted venue must remain in the master map',
      );
      expect(
        after[1]!.isActive,
        isFalse,
        reason: 'master map must reflect the server-side soft-delete',
      );
      expect(fake.deleteCalls, 1);
    },
  );

  test(
    'Issue 509: deleteVenue does not mutate local state when the server '
    'rejects the delete',
    () async {
      final fake = _FakeVenues([_venue(1)])
        ..deleteError = Exception('VENUE_HAS_EVENTS');
      final container = _makeContainer(fake);
      addTearDown(container.dispose);

      await container.read(clVenuesMasterProvider.future);

      await expectLater(
        container.read(clVenuesMasterProvider.notifier).deleteVenue(1),
        throwsA(isA<Exception>()),
      );

      final after = container.read(clVenuesMasterProvider).valueOrNull;
      expect(
        after?[1],
        isNotNull,
        reason: 'a rejected delete must leave the venue in place',
      );
      expect(
        after![1]!.isActive,
        isTrue,
        reason: 'a rejected delete must not flip the venue inactive',
      );
    },
  );
}
