import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

Event _camp({String title = 'camp'}) => Event(
  id: 1,
  version: 1,
  title: title,
  description: '',
  type: EventType.camp,
  visibility: Visibility.public,
  venueId: 1,
  startTimeUtc: DateTime.utc(2026, 6),
  endTimeUtc: DateTime.utc(2026, 6, 1, 2),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

Venue _venue({String name = 'Main Arena'}) => Venue(
  id: 4,
  name: name,
  isDefault: false,
  createdAtUtc: DateTime.utc(2025),
  updatedAtUtc: DateTime.utc(2025),
);

class _Events extends ClEventsMasterNotifier {
  @override
  Future<Map<int, Event>> build() async => {1: _camp()};
}

class _Venues extends ClVenuesMasterNotifier {
  @override
  Future<Map<int, Venue>> build() async => {4: _venue()};
}

UserInfo _info(String username) => UserInfo(
  username: username,
  displayName: username,
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(isMember: true),
);

UserPrivate _private(String username, {String? medicalInfo}) => UserPrivate(
  username: username,
  displayName: username,
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(isMember: true),
  createdAtUtc: DateTime.utc(2025),
  medicalInfo: medicalInfo,
);

class _Users extends ClUsersMasterNotifier {
  @override
  Future<Map<String, UserInfo>> build() async => {
    'bob': _info('bob'),
    'carol': _info('carol'),
  };
}

/// Counts the private-profile fetches.
class _UserSource extends Fake implements UserSource {
  int privateFetches = 0;

  @override
  Future<UserPrivate> getUserPrivate(String username) async {
    privateFetches++;
    return _private(username, medicalInfo: 'fetched');
  }
}

/// Lets every pending microtask and timer-free future settle.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('Issue 229: a master write reaches a detail provider as data', () {
    test(
      'Issue 229: an event save never puts the event detail into loading',
      () async {
        final container = ProviderContainer(
          overrides: [clEventsMasterProvider.overrideWith(_Events.new)],
        );
        addTearDown(container.dispose);
        final states = <AsyncValue<Event>>[];
        container.listen(
          clEventDetailProvider(1),
          (_, next) => states.add(next),
          fireImmediately: true,
        );
        await container.read(clEventsMasterProvider.future);
        await _settle();
        expect(
          container.read(clEventDetailProvider(1)).valueOrNull?.title,
          'camp',
        );
        states.clear();

        container
            .read(clEventsMasterProvider.notifier)
            .replaceLocally(_camp(title: 'renamed'));
        await _settle();

        expect(states.where((s) => s.isLoading), isEmpty);
        expect(states.last.valueOrNull?.title, 'renamed');
      },
    );

    test(
      'Issue 229: a venue save never puts the venue detail into loading',
      () async {
        final container = ProviderContainer(
          overrides: [clVenuesMasterProvider.overrideWith(_Venues.new)],
        );
        addTearDown(container.dispose);
        final states = <AsyncValue<Venue>>[];
        container.listen(
          clVenueDetailProvider(4),
          (_, next) => states.add(next),
          fireImmediately: true,
        );
        await container.read(clVenuesMasterProvider.future);
        await _settle();
        states.clear();

        container
            .read(clVenuesMasterProvider.notifier)
            .replaceLocally(_venue(name: 'North Rink'));
        await _settle();

        expect(states.where((s) => s.isLoading), isEmpty);
        expect(states.last.valueOrNull?.name, 'North Rink');
      },
    );

    test(
      "Issue 229: an absent event is the master's not-found error",
      () async {
        final container = ProviderContainer(
          overrides: [clEventsMasterProvider.overrideWith(_Events.new)],
        );
        addTearDown(container.dispose);
        container.listen(clEventDetailProvider(99), (_, _) {});
        await container.read(clEventsMasterProvider.future);
        await _settle();

        final error = container.read(clEventDetailProvider(99)).error;
        expect(error, isA<StateError>());
        expect('$error', contains('not found in master'));
      },
    );

    group('clUserPrivateProvider', () {
      late _UserSource users;
      late ProviderContainer container;

      setUp(() async {
        users = _UserSource();
        container = ProviderContainer(
          overrides: [
            clUsersMasterProvider.overrideWith(_Users.new),
            secureClientProvider.overrideWith(
              (ref) async => fakeSecureClient(users: users),
            ),
          ],
        );
        // The profile page opens from the members list: the master is in.
        await container.read(clUsersMasterProvider.future);
        container.listen(clUserPrivateProvider('bob'), (_, _) {});
        await container.read(clUserPrivateProvider('bob').future);
      });

      tearDown(() => container.dispose());

      test('Issue 229: the UserPrivate a save returns is used, not fetched '
          'again', () async {
        expect(users.privateFetches, 1);

        container
            .read(clUsersMasterProvider.notifier)
            .replaceLocally(_private('bob', medicalInfo: 'saved'));
        final bob = await container.read(clUserPrivateProvider('bob').future);

        expect(bob.medicalInfo, 'saved');
        expect(users.privateFetches, 1);
      });

      test('Issue 229: a write to another user leaves it alone', () async {
        container
            .read(clUsersMasterProvider.notifier)
            .replaceLocally(_private('carol', medicalInfo: 'saved'));
        await _settle();

        expect(container.read(clUserPrivateProvider('bob')).isLoading, false);
        expect(users.privateFetches, 1);
      });
    });
  });
}
