import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/evaluation_test_harness.dart';
import '../support/fake_evaluation_sources.dart';

const _q1 = EvaluationQaItem(id: 11, question: 'Edges?');
const _q2 = EvaluationQaItem(id: 12, question: 'Stops?');

FakeEvaluations _withTemplates() => FakeEvaluations()
  ..templates[1] = fakeTemplate(1, items: const [_q1, _q2])
  ..templates[2] = fakeTemplate(2, name: 'Shooting');

ClEvaluationTemplatesMasterNotifier _notifier(ProviderContainer c) =>
    c.read(clEvaluationTemplatesMasterProvider.notifier);

void main() {
  group('Issue 173: evaluationsProvider', () {
    test('Issue 173: null until the server answers', () {
      final c = evaluationContainer(on: true);
      expect(c.read(evaluationsProvider), isNull);
    });

    test('Issue 173: reports the server on and off', () async {
      final on = evaluationContainer(on: true);
      await on.read(capabilitiesProvider.future);
      expect(on.read(evaluationsProvider), isTrue);

      final off = evaluationContainer(on: false);
      await off.read(capabilitiesProvider.future);
      expect(off.read(evaluationsProvider), isFalse);
    });
  });

  group('Issue 173: clEvaluationTemplatesMasterProvider', () {
    test('Issue 173: module off → empty, no SDK call', () async {
      final evals = _withTemplates();
      final c = evaluationContainer(on: false, evaluations: evals);

      expect(await settled(c, clEvaluationTemplatesMasterProvider), isEmpty);
      expect(evals.calls, isEmpty);
    });

    test('Issue 173: loads every page of the library', () async {
      final evals = FakeEvaluations();
      for (var i = 1; i <= 150; i++) {
        evals.templates[i] = fakeTemplate(i);
      }
      final c = evaluationContainer(on: true, evaluations: evals);

      final state = await settled(c, clEvaluationTemplatesMasterProvider);

      expect(state.keys, hasLength(150));
      expect(evals.calls, ['listTemplates 0', 'listTemplates 100']);
    });

    test('Issue 173: createTemplate adds the server template', () async {
      final evals = FakeEvaluations();
      final c = evaluationContainer(on: true, evaluations: evals);
      await settled(c, clEvaluationTemplatesMasterProvider);

      final created = await _notifier(c).createTemplate(
        name: 'Passing',
        layout: const [
          EvaluationLayoutItem<EvaluationTemplateItem>(
            EvaluationQaItem(question: 'Accuracy?'),
          ),
        ],
      );

      expect(evals.calls.last, 'createTemplate Passing');
      expect(created.items.single.id, isNotNull);
      final state = c.read(clEvaluationTemplatesMasterProvider).requireValue;
      expect(state[created.id], created);
    });

    test(
      'Issue 173: renameTemplate and updateLayout replace locally',
      () async {
        final evals = _withTemplates();
        final c = evaluationContainer(on: true, evaluations: evals);
        await settled(c, clEvaluationTemplatesMasterProvider);

        await _notifier(c).renameTemplate(1, 'Skating II');
        expect(evals.calls.last, 'updateTemplate 1 Skating II ');
        expect(
          c.read(clEvaluationTemplatesMasterProvider).requireValue[1]!.name,
          'Skating II',
        );

        await _notifier(c).updateLayout(1, const [
          EvaluationLayoutSection<int>('Basics', [12, 11]),
        ]);
        expect(evals.calls.last, 'updateTemplate 1  1');
        expect(
          c.read(clEvaluationTemplatesMasterProvider).requireValue[1]!.layout,
          const [
            EvaluationLayoutSection<int>('Basics', [12, 11]),
          ],
        );
      },
    );

    test('Issue 173: addItem, replaceItem, removeItem', () async {
      final evals = _withTemplates();
      final c = evaluationContainer(on: true, evaluations: evals);
      await settled(c, clEvaluationTemplatesMasterProvider);
      EvaluationTemplate t1() =>
          c.read(clEvaluationTemplatesMasterProvider).requireValue[1]!;

      await _notifier(c).addItem(
        1,
        const EvaluationQaItem(question: 'Crossovers?'),
        section: 'Basics',
      );
      expect(evals.calls.last, 'addItem 1 Basics');
      expect(t1().items, hasLength(3));

      await _notifier(
        c,
      ).replaceItem(1, 11, const EvaluationQaItem(question: 'Inside edges?'));
      expect(evals.calls.last, 'replaceItem 1 11');
      expect(
        (t1().itemById(11)! as EvaluationQaItem).question,
        'Inside edges?',
      );

      await _notifier(c).removeItem(1, 12);
      expect(evals.calls.last, 'removeItem 1 12');
      expect(t1().itemById(12), isNull);
    });

    test('Issue 173: deleteTemplate keeps the deleted row; restore', () async {
      final evals = _withTemplates();
      final c = evaluationContainer(on: true, evaluations: evals);
      await settled(c, clEvaluationTemplatesMasterProvider);

      await _notifier(c).deleteTemplate(2);
      expect(evals.calls.last, 'deleteTemplate 2');
      expect(
        c
            .read(clEvaluationTemplatesMasterProvider)
            .requireValue[2]!
            .deletedAtUtc,
        isNotNull,
      );

      await _notifier(c).restoreTemplate(2);
      expect(evals.calls.last, 'restoreTemplate 2');
      expect(
        c
            .read(clEvaluationTemplatesMasterProvider)
            .requireValue[2]!
            .deletedAtUtc,
        isNull,
      );
    });

    test('Issue 173: a template write bumps evaluationsVersion', () async {
      final c = evaluationContainer(on: true, evaluations: _withTemplates());
      await settled(c, clEvaluationTemplatesMasterProvider);
      final before = c.read(clResourceVersionProvider).evaluationsVersion;

      await _notifier(c).renameTemplate(1, 'X');

      expect(
        c.read(clResourceVersionProvider).evaluationsVersion,
        before + 1,
      );
    });
  });

  group('Issue 173: clEvaluationItemSearchProvider', () {
    const hit = EvaluationTemplateItemHit(
      templateId: 1,
      templateName: 'Skating',
      item: _q1,
    );
    const query = EvaluationItemSearchQuery(
      search: 'edge',
      type: EvaluationItemType.qa,
    );

    test('Issue 173: module off → empty, no SDK call', () async {
      final evals = FakeEvaluations()..hits = const [hit];
      final c = evaluationContainer(on: false, evaluations: evals);

      expect(await settled(c, clEvaluationItemSearchProvider(query)), isEmpty);
      expect(evals.calls, isEmpty);
    });

    test('Issue 173: searches by text and type', () async {
      final evals = FakeEvaluations()..hits = const [hit];
      final c = evaluationContainer(on: true, evaluations: evals);

      final hits = await settled(c, clEvaluationItemSearchProvider(query));

      expect(hits, const [hit]);
      expect(evals.calls, ['searchItems edge qa']);
    });

    test('Issue 173: the query is a value key', () {
      expect(
        const EvaluationItemSearchQuery(search: 'a'),
        EvaluationItemSearchQuery.fromMap(
          const EvaluationItemSearchQuery(search: 'a').toMap(),
        ),
      );
      expect(query.copyWith(type: () => null).type, isNull);
    });
  });
}
