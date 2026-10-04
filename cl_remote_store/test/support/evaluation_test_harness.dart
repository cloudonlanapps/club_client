/// The member-surface and evidence fakes, and a container serving them
/// with [FakeEvaluations] (club_core#173).
library;

import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_evaluation_sources.dart';
import 'fake_secure_client.dart';

/// `/evaluations/by_id/{id}/media`, recording attaches and detaches and
/// reflecting them in [evaluations] as evidence on the answer.
class FakeEvaluationMedia extends Fake implements EvaluationMediaSource {
  FakeEvaluationMedia(this.evaluations);

  final FakeEvaluations evaluations;

  @override
  Future<MediaLink> attach(
    int ownerId, {
    required String tag,
    required String mediaUuid,
    String? metadata,
  }) async {
    evaluations.calls.add('attach $ownerId $tag $mediaUuid');
    _setEvidence(
      ownerId,
      tag,
      (e) => [...e, EvaluationEvidence(mediaUuid: mediaUuid)],
    );
    return fakeMediaLink(tag, mediaUuid);
  }

  @override
  Future<void> detach(int ownerId, String tag, String mediaUuid) async {
    evaluations.calls.add('detach $ownerId $tag $mediaUuid');
    _setEvidence(
      ownerId,
      tag,
      (e) => e.where((x) => x.mediaUuid != mediaUuid).toList(),
    );
  }

  void _setEvidence(
    int id,
    String tag,
    List<EvaluationEvidence> Function(List<EvaluationEvidence>) change,
  ) {
    final itemId = EvaluationMediaTags.itemIdOf(tag)!;
    final view = evaluations.evaluations[id]!;
    evaluations.evaluations[id] = view.copyWith(
      answers: [
        for (final a in view.answers)
          if (a.itemId == itemId)
            EvaluationAnswer(
              itemId: a.itemId,
              valueNum: a.valueNum,
              valueText: a.valueText,
              coachNote: a.coachNote,
              evidence: change(a.evidence),
            )
          else
            a,
      ],
    );
  }
}

/// A link of [mediaUuid] under [tag].
MediaLink fakeMediaLink(String tag, String mediaUuid) => MediaLink(
  tag: tag,
  media: MediaRef(
    uuid: mediaUuid,
    mimeType: 'application/pdf',
    filename: '$mediaUuid.pdf',
  ),
  createdAtUtc: fakeEvaluationTime,
  updatedAtUtc: fakeEvaluationTime,
);

/// `/myevaluations` over a fixed list and media map, counting calls.
class FakeMyEvaluations extends Fake implements MyEvaluationsSource {
  FakeMyEvaluations({this.views = const [], this.media = const {}});

  List<EvaluationMemberView> views;
  final Map<String, List<MediaLink>> media;
  int listCalls = 0;
  int mediaCalls = 0;

  @override
  Future<PaginatedList<EvaluationMemberView>> listMyEvaluations(
    String username, {
    int offset = 0,
    int limit = 20,
  }) async {
    listCalls++;
    final mine = views.where((v) => v.createdFor == username).toList();
    return PaginatedList(
      items: mine.skip(offset).take(limit).toList(),
      total: mine.length,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<Map<String, List<MediaLink>>> listMyEvaluationMedia(
    String username,
    int id,
  ) async {
    mediaCalls++;
    return media;
  }
}

/// A published member view for [createdFor].
EvaluationMemberView fakeMemberView(int id, {String createdFor = 'member'}) =>
    EvaluationMemberView(
      id: id,
      createdFor: createdFor,
      createdBy: 'coach',
      status: EvaluationStatus.published,
      publishedAtUtc: fakeEvaluationTime,
      template: const EvaluationMemberTemplate(
        id: 1,
        name: 'Skating',
        layout: [],
        items: [],
      ),
      answers: const [],
    );

/// A container whose client serves the given evaluation fakes, with the
/// evaluations capability [on] or off.
ProviderContainer evaluationContainer({
  required bool on,
  FakeEvaluations? evaluations,
  FakeMyEvaluations? myEvaluations,
}) {
  final evals = evaluations ?? FakeEvaluations();
  final container = ProviderContainer(
    overrides: [
      secureClientProvider.overrideWith(
        (ref) async => fakeSecureClient(
          capabilities: EvaluationCapabilities(evaluations: on),
          evaluations: evals,
          evaluationMedia: FakeEvaluationMedia(evals),
          myEvaluations: myEvaluations ?? FakeMyEvaluations(),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Reads [p] once the capabilities have answered and it has settled.
Future<T> settled<T>(
  ProviderContainer c,
  ProviderListenable<AsyncValue<T>> p,
) async {
  final sub = c.listen(p, (_, _) {});
  addTearDown(sub.close);
  await c.read(capabilitiesProvider.future);
  for (var i = 0; i < 100; i++) {
    final v = c.read(p);
    if (v.hasValue && !v.isLoading) return v.requireValue;
    await Future<void>.delayed(Duration.zero);
  }
  throw StateError('$p did not settle');
}
