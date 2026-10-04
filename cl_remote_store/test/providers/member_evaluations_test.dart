import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/evaluation_test_harness.dart';
import '../support/fake_evaluation_sources.dart';

const MemberEvaluationKey _key = (username: 'member', evaluationId: 1);

void main() {
  group('Issue 173: clMemberEvaluationsProvider', () {
    test('Issue 173: module off → empty, no SDK call', () async {
      final mine = FakeMyEvaluations(views: [fakeMemberView(1)]);
      final c = evaluationContainer(on: false, myEvaluations: mine);

      expect(await settled(c, clMemberEvaluationsProvider('member')), isEmpty);
      expect(mine.listCalls, 0);
    });

    test("Issue 173: lists the member's published evaluations", () async {
      final mine = FakeMyEvaluations(
        views: [
          fakeMemberView(1),
          fakeMemberView(2),
          fakeMemberView(3, createdFor: 'other'),
        ],
      );
      final c = evaluationContainer(on: true, myEvaluations: mine);

      final views = await settled(c, clMemberEvaluationsProvider('member'));

      expect(views.map((v) => v.id), [1, 2]);
      expect(mine.listCalls, 1);
    });

    test('Issue 173: refetches when an evaluation write lands', () async {
      final evals = FakeEvaluations()..evaluations[1] = fakeStaffView(1);
      final mine = FakeMyEvaluations();
      final c = evaluationContainer(
        on: true,
        evaluations: evals,
        myEvaluations: mine,
      );
      expect(await settled(c, clMemberEvaluationsProvider('member')), isEmpty);
      await settled(c, clEvaluationsMasterProvider);

      mine.views = [fakeMemberView(1)];
      await c.read(clEvaluationsMasterProvider.notifier).publishEvaluation(1);

      final views = await settled(c, clMemberEvaluationsProvider('member'));
      expect(views.map((v) => v.id), [1]);
      expect(mine.listCalls, 2);
    });
  });

  group('Issue 173: clMemberEvaluationMediaProvider', () {
    test('Issue 173: module off → null, no SDK call', () async {
      final mine = FakeMyEvaluations();
      final c = evaluationContainer(on: false, myEvaluations: mine);

      expect(await settled(c, clMemberEvaluationMediaProvider(_key)), isNull);
      expect(mine.mediaCalls, 0);
    });

    test('Issue 173: splits the member copy from the evidence', () async {
      final copy = fakeMediaLink(EvaluationMediaTags.memberCopy, 'pdf-1');
      final e1 = fakeMediaLink(EvaluationMediaTags.evidence(11), 'e-1');
      final e2 = fakeMediaLink(EvaluationMediaTags.evidence(12), 'e-2');
      final mine = FakeMyEvaluations(
        media: {
          EvaluationMediaTags.memberCopy: [copy],
          EvaluationMediaTags.evidence(11): [e1],
          EvaluationMediaTags.evidence(12): [e2],
          'unknown': [fakeMediaLink('unknown', 'x')],
        },
      );
      final c = evaluationContainer(on: true, myEvaluations: mine);

      final media = await settled(c, clMemberEvaluationMediaProvider(_key));

      expect(media!.memberCopy, copy);
      expect(media.evidence, {
        11: [e1],
        12: [e2],
      });
      expect(media.evidenceFor(13), isEmpty);
      expect(mine.mediaCalls, 1);
    });

    test('Issue 173: no stored copy → memberCopy is null', () async {
      final c = evaluationContainer(
        on: true,
        myEvaluations: FakeMyEvaluations(),
      );

      final media = await settled(c, clMemberEvaluationMediaProvider(_key));

      expect(media!.memberCopy, isNull);
      expect(media.evidence, isEmpty);
    });
  });
}
