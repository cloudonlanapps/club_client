import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

/// Fake [EventMarketingSource]: one event's block, or none.
class _FakeMarketing extends Fake implements EventMarketingSource {
  EventMarketing? stored;

  /// When set, the next write throws this instead of applying.
  Exception? writeError;

  int reads = 0;
  final List<int> versionsSent = [];

  @override
  Future<EventMarketing> getEventMarketing(int eventId) async {
    reads++;
    final block = stored;
    if (block == null) {
      throw const ServerException(
        statusCode: 404,
        code: SdkErrorCode.eventMarketingNotFound,
        message: 'none',
      );
    }
    return block;
  }

  @override
  Future<EventMarketing> setEventMarketing(
    int eventId,
    EventMarketing marketing, {
    required int version,
  }) async {
    versionsSent.add(version);
    final error = writeError;
    if (error != null) {
      writeError = null;
      throw error;
    }
    return stored = EventMarketing(
      durationText: marketing.durationText,
      fee: marketing.fee,
      version: version + 1,
    );
  }

  @override
  Future<void> clearEventMarketing(int eventId, {required int version}) async {
    versionsSent.add(version);
    stored = null;
  }
}

void main() {
  group("Issue 1: an event's extended marketing block for staff", () {
    late _FakeMarketing fake;
    late ProviderContainer container;

    setUp(() {
      fake = _FakeMarketing();
      container = ProviderContainer(
        overrides: [
          secureClientProvider.overrideWith(
            (ref) async => fakeSecureClient(eventMarketing: fake),
          ),
        ],
      );
    });

    tearDown(() => container.dispose());

    test(
      'Issue 1: an event with none reads as an empty, unwritten block',
      () async {
        final block = await container.read(
          clEventMarketingMasterProvider(7).future,
        );

        expect(block, const EventMarketing());
        expect(block.version, EventMarketing.unwrittenVersion);
      },
    );

    test(
      'Issue 1: a save sends the version loaded and keeps the answer',
      () async {
        await container.read(clEventMarketingMasterProvider(7).future);
        final notifier = container.read(
          clEventMarketingMasterProvider(7).notifier,
        );

        await notifier.save(const EventMarketing(fee: 500));
        await notifier.save(const EventMarketing(fee: 600));

        expect(fake.versionsSent, [1, 2]);
        expect(
          container.read(clEventMarketingMasterProvider(7)).valueOrNull?.fee,
          600,
        );
      },
    );

    test('Issue 1: a clear removes the block', () async {
      fake.stored = const EventMarketing(fee: 500, version: 4);
      await container.read(clEventMarketingMasterProvider(7).future);

      await container.read(clEventMarketingMasterProvider(7).notifier).clear();

      expect(fake.versionsSent, [4]);
      expect(
        container.read(clEventMarketingMasterProvider(7)).valueOrNull,
        const EventMarketing(),
      );
    });

    test('Issue 1: a stale save reloads the block and rethrows', () async {
      await container.read(clEventMarketingMasterProvider(7).future);
      fake
        ..stored = const EventMarketing(durationText: 'theirs', version: 5)
        ..writeError = const StaleVersionException(
          message: 'stale',
          version: 5,
          updatedBy: 'another_admin',
        );

      await expectLater(
        container
            .read(clEventMarketingMasterProvider(7).notifier)
            .save(const EventMarketing(fee: 500)),
        throwsA(isA<StaleVersionException>()),
      );
      final reloaded = await container.read(
        clEventMarketingMasterProvider(7).future,
      );

      expect(reloaded.durationText, 'theirs');
      expect(reloaded.version, 5);
    });
  });

  group('Issue 1: whether the deployment runs Event Marketing', () {
    test('Issue 1: unknown until the capabilities answer', () {
      final container = ProviderContainer(
        overrides: [
          capabilitiesProvider.overrideWith(
            (ref) => Future<Capabilities>.delayed(
              const Duration(days: 1),
              () => const Capabilities(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(eventMarketingProvider), isNull);
    });

    test('Issue 1: the capabilities say so', () async {
      final container = ProviderContainer(
        overrides: [
          capabilitiesProvider.overrideWith(
            (ref) async => const Capabilities(eventMarketing: true),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(capabilitiesProvider.future);

      expect(container.read(eventMarketingProvider), isTrue);
    });
  });
}
