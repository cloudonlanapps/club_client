import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_public_source.dart';

void main() {
  group('Issue 53: public staff and venues', () {
    test('Issue 53: clPublicStaffProvider lists the staff page without '
        'guests', () async {
      final source = FakePublicSource()
        ..staff = const [PublicProfile(publicId: 'c1', displayName: 'Coach')];
      final container = publicContainer(source);
      final sub = container.listen(clPublicStaffProvider, (_, _) {});
      addTearDown(sub.close);

      final staff = await container.read(clPublicStaffProvider.future);

      expect(staff.single.publicId, 'c1');
      expect(source.staffGuestArgs, [false]);
    });

    test('Issue 53: clPublicVenuesProvider lists every live venue', () async {
      final source = FakePublicSource()
        ..venues = [testVenue('v1'), testVenue('v2')];
      final container = publicContainer(source);
      final sub = container.listen(clPublicVenuesProvider, (_, _) {});
      addTearDown(sub.close);

      final venues = await container.read(clPublicVenuesProvider.future);

      expect(venues.map((v) => v.publicId), ['v1', 'v2']);
    });

    test(
      'Issue 53: clPublicVenueProvider reads one venue by public id',
      () async {
        final source = FakePublicSource()..venue = testVenue('v9');
        final container = publicContainer(source);
        final sub = container.listen(clPublicVenueProvider('v9'), (_, _) {});
        addTearDown(sub.close);

        final venue = await container.read(clPublicVenueProvider('v9').future);

        expect(venue.publicId, 'v9');
        expect(source.calls, ['getPublicVenue:v9']);
      },
    );
  });

  group('Issue 53: public reads report to the network monitor', () {
    test('Issue 53: a successful read marks the server online', () async {
      final source = FakePublicSource()..venues = [testVenue('v1')];
      final container = publicContainer(source);
      final sub = container.listen(clPublicVenuesProvider, (_, _) {});
      addTearDown(sub.close);

      await container.read(clPublicVenuesProvider.future);

      final monitor = networkMonitor(container);
      expect(monitor.onlines, 1);
      expect(monitor.checks, 0);
    });

    test(
      'Issue 53: a failed read asks the monitor to check, and fails',
      () async {
        final source = FakePublicSource()
          ..failWith = Exception('connection refused');
        final container = publicContainer(source);
        final sub = container.listen(clPublicStaffProvider, (_, _) {});
        addTearDown(sub.close);

        await expectLater(
          container.read(clPublicStaffProvider.future),
          throwsException,
        );

        final monitor = networkMonitor(container);
        expect(monitor.checks, 1);
        expect(monitor.onlines, 0);
      },
    );
  });
}
