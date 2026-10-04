import 'package:cl_club_events/cl_club_events.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:cl_server_config/cl_server_config.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _base = 'https://api.example.com/v1';

PublicEvent _event(String publicId, {bool isPast = false}) => PublicEvent(
  publicId: publicId,
  title: 'Event $publicId',
  description: '',
  type: EventType.camp,
  venueId: 'v1',
  startTimeUtc: DateTime.utc(2026, 10),
  endTimeUtc: DateTime.utc(2026, 10, 2),
  venue: const PublicVenue(publicId: 'v1', name: 'Rink'),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
  isPast: isPast,
);

ProviderContainer _container(List<Override> overrides) {
  final container = ProviderContainer(
    overrides: [
      serverConfigProvider.overrideWithValue(
        const ServerConfig(baseUrl: _base),
      ),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('Issue 53: the public event providers', () {
    test('Issue 53: event listings split active from past', () async {
      final container = _container([
        clPublicEventsProvider(EventType.camp).overrideWith(
          (ref) async => [_event('a'), _event('p', isPast: true)],
        ),
      ]);
      final sub = container.listen(
        publicEventsByTypeProvider(EventType.camp),
        (_, _) {},
      );
      addTearDown(sub.close);

      final split = await container.read(
        publicEventsByTypeProvider(EventType.camp).future,
      );

      expect(split.active.map((e) => e.publicId), ['a']);
      expect(split.past.map((e) => e.publicId), ['p']);
      expect(split.active.single.media.apiBaseUrl, _base);
    });

    test('Issue 53: an event that cannot be read is not found', () async {
      final container = _container([
        clPublicEventProvider(
          'gone',
        ).overrideWith((ref) async => throw Exception('404')),
        clPublicEventMarketingProvider(
          'gone',
        ).overrideWith((ref) async => null),
      ]);
      final sub = container.listen(publicEventByIdProvider('gone'), (_, _) {});
      addTearDown(sub.close);

      expect(
        await container.read(publicEventByIdProvider('gone').future),
        isNull,
      );
    });

    test(
      'Issue 53: an event carries its marketing block when there is one',
      () async {
        const block = EventMarketing(scheduleText: 'Weekends');
        final container = _container([
          clPublicEventProvider('e1').overrideWith((ref) async => _event('e1')),
          clPublicEventMarketingProvider(
            'e1',
          ).overrideWith((ref) async => block),
        ]);
        final sub = container.listen(publicEventByIdProvider('e1'), (_, _) {});
        addTearDown(sub.close);

        final view = await container.read(publicEventByIdProvider('e1').future);

        expect(view!.publicId, 'e1');
        expect(view.marketing, block);
      },
    );

    test('Issue 53: the featured events are the highlights', () async {
      final container = _container([
        clPublicFeaturedEventsProvider.overrideWith(
          (ref) async => [_event('f1'), _event('f2')],
        ),
      ]);
      final sub = container.listen(publicHighlightsProvider, (_, _) {});
      addTearDown(sub.close);

      final highlights = await container.read(
        publicHighlightsProvider.future,
      );

      expect(highlights.map((h) => h.id), ['f1', 'f2']);
      expect(highlights.first, isA<EventHighlight>());
      expect(highlights.first.type, HighlightType.camp);
    });
  });
}
