import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_public_source.dart';

void main() {
  group('Issue 53: the public event catalogue', () {
    test(
      'Issue 53: clPublicEventsProvider lists one type, a full page',
      () async {
        final source = FakePublicSource()
          ..events = [testEvent('e1'), testEvent('e2', isPast: true)];
        final container = publicContainer(source);
        final sub = container.listen(
          clPublicEventsProvider(EventType.programme),
          (_, _) {},
        );
        addTearDown(sub.close);

        final events = await container.read(
          clPublicEventsProvider(EventType.programme).future,
        );

        expect(events.map((e) => e.publicId), ['e1', 'e2']);
        expect(source.listEventArgs.single, {
          'type': EventType.programme,
          'featured': null,
          'limit': publicEventsPageLimit,
        });
      },
    );

    test('Issue 53: clPublicFeaturedEventsProvider asks for featured events '
        'of every type', () async {
      final source = FakePublicSource()
        ..events = [testEvent('f1', isFeatured: true)];
      final container = publicContainer(source);
      final sub = container.listen(clPublicFeaturedEventsProvider, (_, _) {});
      addTearDown(sub.close);

      final events = await container.read(
        clPublicFeaturedEventsProvider.future,
      );

      expect(events.single.publicId, 'f1');
      expect(source.listEventArgs.single, {
        'type': null,
        'featured': true,
        'limit': publicEventsPageLimit,
      });
    });

    test(
      'Issue 53: clPublicEventProvider reads one event by public id',
      () async {
        final source = FakePublicSource()..event = testEvent('abc');
        final container = publicContainer(source);
        final sub = container.listen(clPublicEventProvider('abc'), (_, _) {});
        addTearDown(sub.close);

        final event = await container.read(clPublicEventProvider('abc').future);

        expect(event.publicId, 'abc');
        expect(source.calls, ['getPublicEvent:abc']);
      },
    );

    test(
      'Issue 53: clPublicEventMarketingProvider holds the extended block',
      () async {
        const block = EventMarketing(scheduleText: 'Weekends');
        final source = FakePublicSource()..marketing = block;
        final container = publicContainer(source);
        final sub = container.listen(
          clPublicEventMarketingProvider('abc'),
          (_, _) {},
        );
        addTearDown(sub.close);

        expect(
          await container.read(clPublicEventMarketingProvider('abc').future),
          block,
        );
      },
    );

    test('Issue 53: clPublicEventMarketingProvider is null when the module is '
        'off or the event has no block', () async {
      for (final error in <Exception>[
        const ModuleDisabledException(code: 'MODULE_DISABLED', message: 'off'),
        const ServerException(
          statusCode: 404,
          code: 'NOT_FOUND',
          message: 'none',
        ),
      ]) {
        final source = FakePublicSource()..marketingError = error;
        final container = publicContainer(source);
        final sub = container.listen(
          clPublicEventMarketingProvider('abc'),
          (_, _) {},
        );
        addTearDown(sub.close);

        expect(
          await container.read(clPublicEventMarketingProvider('abc').future),
          isNull,
        );
      }
    });

    test(
      'Issue 53: the public providers dispose when nothing watches them',
      () async {
        final source = FakePublicSource()..events = [testEvent('e1')];
        final container = publicContainer(source);

        var sub = container.listen(
          clPublicEventsProvider(EventType.camp),
          (_, _) {},
        );
        await container.read(clPublicEventsProvider(EventType.camp).future);
        sub.close();
        await container.pump();

        sub = container.listen(
          clPublicEventsProvider(EventType.camp),
          (_, _) {},
        );
        addTearDown(sub.close);
        await container.read(clPublicEventsProvider(EventType.camp).future);

        expect(source.listEventArgs, hasLength(2));
      },
    );
  });
}
