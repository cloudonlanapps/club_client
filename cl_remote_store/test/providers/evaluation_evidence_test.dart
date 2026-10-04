import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/evaluation_test_harness.dart';
import '../support/fake_evaluation_sources.dart';
import '../support/fake_secure_client.dart';

/// `/media`, failing any call: evidence never goes through it.
class _UnusedMedia extends Fake implements MediaSource {}

/// `/evaluations/by_id/{id}/media` listing over a fixed map.
class _FakeEvaluationMediaListing extends FakeEvaluationMedia {
  _FakeEvaluationMediaListing(super.evaluations, this.grouped);

  final Map<String, List<MediaLink>> grouped;
  int listCalls = 0;

  @override
  Future<Map<String, List<MediaLink>>> listGrouped(int ownerId) async {
    listCalls++;
    return grouped;
  }
}

ProviderContainer _container({
  required bool on,
  required _FakeEvaluationMediaListing evaluationMedia,
}) {
  final container = ProviderContainer(
    overrides: [
      secureClientProvider.overrideWith(
        (ref) async => fakeSecureClient(
          capabilities: EvaluationCapabilities(evaluations: on),
          evaluations: evaluationMedia.evaluations,
          evaluationMedia: evaluationMedia,
          media: _UnusedMedia(),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('Issue 173: evaluation evidence', () {
    test(
      'Issue 173: uploadEvidence uploads and links the file in one '
      'call, replaces the evaluation locally and bumps the version',
      () async {
        final evals = FakeEvaluations()
          ..evaluations[1] = fakeStaffView(
            1,
            answers: const [EvaluationAnswer(itemId: 11, valueText: 'Good')],
          );
        final c = _container(
          on: true,
          evaluationMedia: _FakeEvaluationMediaListing(evals, {}),
        );
        await settled(c, clEvaluationsMasterProvider);
        final before = c.read(clResourceVersionProvider).evaluationsVersion;

        final view = await c
            .read(clEvaluationsMasterProvider.notifier)
            .uploadEvidence(
              1,
              11,
              bytes: const [1, 2, 3],
              filename: 'drill.png',
              contentType: 'image/png',
            );

        expect(evals.calls.skip(1), [
          'uploadEvidence 1 11 drill.png image/png',
        ]);
        final held = c.read(clEvaluationsMasterProvider).requireValue[1]!;
        expect(held, view);
        expect(held.answerFor(11)!.evidence.map((e) => e.mediaUuid), [
          'uuid-drill.png',
        ]);
        expect(
          c.read(clResourceVersionProvider).evaluationsVersion,
          before + 1,
        );
      },
    );

    test("Issue 173: clEvaluationMediaProvider splits the owner's listing "
        'into evidence by item and the member copy', () async {
      final listing = _FakeEvaluationMediaListing(FakeEvaluations(), {
        '11': [fakeMediaLink('11', 'a')],
        EvaluationMediaTags.memberCopy: [
          fakeMediaLink(EvaluationMediaTags.memberCopy, 'copy'),
        ],
      });
      final c = _container(on: true, evaluationMedia: listing);

      final media = await settled(c, clEvaluationMediaProvider(1));

      expect(media!.evidenceFor(11).single.mediaUuid, 'a');
      expect(media.memberCopy!.mediaUuid, 'copy');
      expect(listing.listCalls, 1);
    });

    test('Issue 173: clEvaluationMediaProvider is null with the module off, '
        'and calls nothing', () async {
      final listing = _FakeEvaluationMediaListing(FakeEvaluations(), {});
      final c = _container(on: false, evaluationMedia: listing);

      expect(await settled(c, clEvaluationMediaProvider(1)), isNull);
      expect(listing.listCalls, 0);
    });
  });
}
