import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/evaluation_test_harness.dart';
import '../support/fake_evaluation_sources.dart';

const _item = 11;

FakeEvaluations _withDrafts() => FakeEvaluations()
  ..evaluations[1] = fakeStaffView(
    1,
    answers: const [EvaluationAnswer(itemId: _item, valueText: 'Good')],
  )
  ..evaluations[2] = fakeStaffView(2, createdFor: 'other');

ClEvaluationsMasterNotifier _notifier(ProviderContainer c) =>
    c.read(clEvaluationsMasterProvider.notifier);

EvaluationStaffView _view(ProviderContainer c, int id) =>
    c.read(clEvaluationsMasterProvider).requireValue[id]!;

int _version(ProviderContainer c) =>
    c.read(clResourceVersionProvider).evaluationsVersion;

void main() {
  group('Issue 173: clEvaluationsMasterProvider', () {
    test('Issue 173: module off → empty, no SDK call', () async {
      final evals = _withDrafts();
      final c = evaluationContainer(on: false, evaluations: evals);

      expect(await settled(c, clEvaluationsMasterProvider), isEmpty);
      expect(evals.calls, isEmpty);
    });

    test("Issue 173: loads the caller's evaluations", () async {
      final evals = _withDrafts();
      final c = evaluationContainer(on: true, evaluations: evals);

      final state = await settled(c, clEvaluationsMasterProvider);

      expect(state.keys, unorderedEquals([1, 2]));
      expect(evals.calls, ['listEvaluations']);
    });

    test('Issue 173: createEvaluation adds the server draft', () async {
      final evals = FakeEvaluations();
      final c = evaluationContainer(on: true, evaluations: evals);
      await settled(c, clEvaluationsMasterProvider);

      final created = await _notifier(
        c,
      ).createEvaluation(templateId: 7, createdFor: 'member', eventId: 3);

      expect(evals.calls.last, 'createEvaluation 7 member 3');
      expect(_view(c, created.id), created);
      expect(created.eventId, 3);
    });

    test('Issue 173: updateEvaluation moves the draft to an event and a '
        'period, and replaces it locally', () async {
      final evals = _withDrafts();
      final c = evaluationContainer(on: true, evaluations: evals);
      await settled(c, clEvaluationsMasterProvider);
      final start = DateTime.utc(2026, 8);
      final end = DateTime.utc(2026, 9);

      await _notifier(c).updateEvaluation(
        1,
        eventId: () => 4,
        periodStartUtc: () => start,
        periodEndUtc: () => end,
      );

      expect(
        evals.calls.last,
        'updateEvaluation 1 event=4 start=$start end=$end',
      );
      expect(_view(c, 1).eventId, 4);
      expect(_view(c, 1).periodStartUtc, start);
      expect(_view(c, 1).periodEndUtc, end);
    });

    test('Issue 173: updateEvaluation sends only the fields given; a getter '
        'returning null makes the draft general', () async {
      final evals = FakeEvaluations()
        ..evaluations[1] = fakeStaffView(1).copyWith(
          eventId: () => 4,
          periodStartUtc: () => DateTime.utc(2026, 8),
          periodEndUtc: () => DateTime.utc(2026, 9),
        );
      final c = evaluationContainer(on: true, evaluations: evals);
      await settled(c, clEvaluationsMasterProvider);

      await _notifier(c).updateEvaluation(1, eventId: () => null);

      expect(evals.calls.last, 'updateEvaluation 1 event=null start=- end=-');
      expect(_view(c, 1).eventId, isNull);
      expect(_view(c, 1).periodStartUtc, DateTime.utc(2026, 8));
    });

    test('Issue 173: putAnswer and clearAnswer use the server view', () async {
      final evals = _withDrafts();
      final c = evaluationContainer(on: true, evaluations: evals);
      await settled(c, clEvaluationsMasterProvider);

      await _notifier(
        c,
      ).putAnswer(1, 12, const EvaluationAnswerInput(valueText: 'Fine'));
      expect(evals.calls.last, 'putAnswer 1 12');
      expect(_view(c, 1).answerFor(12)?.valueText, 'Fine');

      await _notifier(c).clearAnswer(1, _item);
      expect(evals.calls.last, 'clearAnswer 1 $_item');
      expect(_view(c, 1).answerFor(_item), isNull);
    });

    test('Issue 173: lifecycle steps take the server status', () async {
      final evals = _withDrafts();
      final c = evaluationContainer(on: true, evaluations: evals);
      await settled(c, clEvaluationsMasterProvider);
      final n = _notifier(c);

      await n.saveEvaluation(1);
      expect(_view(c, 1).status, EvaluationStatus.saved);
      await n.publishEvaluation(1);
      expect(_view(c, 1).status, EvaluationStatus.published);
      await n.unpublishEvaluation(1);
      expect(_view(c, 1).status, EvaluationStatus.saved);
      await n.revertEvaluation(1);
      expect(_view(c, 1).status, EvaluationStatus.draft);

      expect(evals.calls.skip(1), [
        'saveEvaluation 1',
        'publishEvaluation 1',
        'unpublishEvaluation 1',
        'revertEvaluation 1',
      ]);
    });

    test('Issue 173: INCOMPLETE propagates with its item ids', () async {
      final evals = _withDrafts()
        ..saveError = const ServerException(
          statusCode: 422,
          code: SdkErrorCode.incomplete,
          message: 'incomplete',
          details: {
            'details': {
              'itemIds': [11, 13],
            },
          },
        );
      final c = evaluationContainer(on: true, evaluations: evals);
      await settled(c, clEvaluationsMasterProvider);

      Object? caught;
      try {
        await _notifier(c).saveEvaluation(1);
      } on Object catch (e) {
        caught = e;
      }

      expect(caught, isA<ServerException>());
      expect(evaluationIncompleteItemIds(caught!), [11, 13]);
      expect(_view(c, 1).status, EvaluationStatus.draft);
    });

    test('Issue 173: evaluationIncompleteItemIds is null otherwise', () {
      expect(evaluationIncompleteItemIds(StateError('x')), isNull);
      expect(
        evaluationIncompleteItemIds(
          const ServerException(
            statusCode: 422,
            code: 'INVALID_STATE',
            message: 'x',
          ),
        ),
        isNull,
      );
    });

    test('Issue 173: transferEvaluation removes it locally', () async {
      final evals = _withDrafts();
      final c = evaluationContainer(on: true, evaluations: evals);
      await settled(c, clEvaluationsMasterProvider);

      await _notifier(c).transferEvaluation(1, owner: 'coach2');

      expect(evals.calls.last, 'transferEvaluation 1 coach2');
      expect(
        c.read(clEvaluationsMasterProvider).requireValue.containsKey(1),
        isFalse,
      );
    });

    test(
      'Issue 173: deleteEvaluation keeps the deleted row; restore',
      () async {
        final evals = _withDrafts();
        final c = evaluationContainer(on: true, evaluations: evals);
        await settled(c, clEvaluationsMasterProvider);

        await _notifier(c).deleteEvaluation(2);
        expect(evals.calls.last, 'deleteEvaluation 2');
        expect(_view(c, 2).deletedAtUtc, isNotNull);

        await _notifier(c).restoreEvaluation(2);
        expect(evals.calls.last, 'restoreEvaluation 2');
        expect(_view(c, 2).deletedAtUtc, isNull);
      },
    );

    test('Issue 173: detachEvidence refetches the view', () async {
      final evals = _withDrafts();
      final c = evaluationContainer(on: true, evaluations: evals);
      await settled(c, clEvaluationsMasterProvider);
      await _notifier(
        c,
      ).uploadEvidence(1, _item, bytes: const [1], filename: 'a.pdf');

      await _notifier(c).detachEvidence(1, _item, 'uuid-a.pdf');
      expect(evals.calls.skip(2), [
        'detach 1 ${EvaluationMediaTags.evidence(_item)} uuid-a.pdf',
        'getEvaluation 1',
      ]);
      expect(_view(c, 1).answerFor(_item)!.evidence, isEmpty);
    });

    test('Issue 173: previewPdf returns the bytes, state unchanged', () async {
      final evals = _withDrafts();
      final c = evaluationContainer(on: true, evaluations: evals);
      final before = await settled(c, clEvaluationsMasterProvider);

      final bytes = await _notifier(c).previewPdf(1);

      expect(bytes, isNotEmpty);
      expect(evals.calls.last, 'previewMemberCopy 1');
      expect(c.read(clEvaluationsMasterProvider).requireValue, before);
    });

    test(
      'Issue 173: every evaluation write bumps evaluationsVersion',
      () async {
        final evals = _withDrafts();
        final c = evaluationContainer(on: true, evaluations: evals);
        await settled(c, clEvaluationsMasterProvider);
        final n = _notifier(c);
        var expected = _version(c);

        Future<void> bumps(Future<Object?> Function() write) async {
          await write();
          expect(_version(c), ++expected);
        }

        await bumps(() => n.createEvaluation(templateId: 1, createdFor: 'm'));
        await bumps(
          () => n.updateEvaluation(
            1,
            periodStartUtc: () => null,
            periodEndUtc: () => null,
          ),
        );
        await bumps(
          () => n.putAnswer(1, 12, const EvaluationAnswerInput(valueNum: 1)),
        );
        await bumps(() => n.clearAnswer(1, 12));
        await bumps(
          () => n.uploadEvidence(1, _item, bytes: const [1], filename: 'm'),
        );
        await bumps(() => n.detachEvidence(1, _item, 'uuid-m'));
        await bumps(() => n.saveEvaluation(1));
        await bumps(() => n.publishEvaluation(1));
        await bumps(() => n.unpublishEvaluation(1));
        await bumps(() => n.revertEvaluation(1));
        await bumps(() => n.deleteEvaluation(2));
        await bumps(() => n.restoreEvaluation(2));
        await bumps(() => n.transferEvaluation(2, owner: 'c'));
        // The master itself keeps its state across the bumps.
        expect(evals.calls.where((x) => x == 'listEvaluations'), hasLength(1));
      },
    );
  });
}
