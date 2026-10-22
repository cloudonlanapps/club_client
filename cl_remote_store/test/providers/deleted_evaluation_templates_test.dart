import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/evaluation_test_harness.dart';
import '../support/fake_evaluation_sources.dart';

FakeEvaluations _library() => FakeEvaluations()
  ..templates[1] = fakeTemplate(1)
  ..templates[2] = fakeTemplate(
    2,
    name: 'Shooting',
    deletedAtUtc: fakeEvaluationTime,
  );

List<String> _names(ProviderContainer c) => [
  for (final t in c.read(clDeletedEvaluationTemplatesProvider).requireValue)
    t.name,
];

void main() {
  group('Issue 277: clDeletedEvaluationTemplatesProvider', () {
    test('Issue 277: module off → empty, no SDK call', () async {
      final evals = _library();
      final c = evaluationContainer(on: false, evaluations: evals);

      expect(await settled(c, clDeletedEvaluationTemplatesProvider), isEmpty);
      expect(evals.calls, isEmpty);
    });

    test('Issue 277: lists only the deleted templates, all pages', () async {
      final evals = _library();
      for (var i = 10; i < 160; i++) {
        evals.templates[i] = fakeTemplate(
          i,
          name: 'Old $i',
          deletedAtUtc: fakeEvaluationTime,
        );
      }
      final c = evaluationContainer(on: true, evaluations: evals);

      final deleted = await settled(c, clDeletedEvaluationTemplatesProvider);

      expect(deleted, hasLength(151));
      expect(deleted.map((t) => t.id), isNot(contains(1)));
      expect(evals.calls, [
        'listDeletedTemplates 0',
        'listDeletedTemplates 100',
      ]);
    });

    test('Issue 277: a delete adds the row, a restore takes it away', () async {
      final evals = _library();
      final c = evaluationContainer(on: true, evaluations: evals);
      await settled(c, clEvaluationTemplatesMasterProvider);
      expect(await settled(c, clDeletedEvaluationTemplatesProvider), [
        evals.templates[2],
      ]);

      await c
          .read(clEvaluationTemplatesMasterProvider.notifier)
          .deleteTemplate(1);
      await settled(c, clDeletedEvaluationTemplatesProvider);
      expect(_names(c), unorderedEquals(['Skating', 'Shooting']));

      final restored = await c
          .read(clEvaluationTemplatesMasterProvider.notifier)
          .restoreTemplate(2);
      await settled(c, clDeletedEvaluationTemplatesProvider);

      expect(restored.name, 'Shooting');
      expect(_names(c), ['Skating']);
      expect(
        c.read(clEvaluationTemplatesMasterProvider).requireValue[2],
        restored,
      );
    });

    test(
      'Issue 277: a restore onto a taken name returns the new name',
      () async {
        final evals = _library()
          ..templates[3] = fakeTemplate(3, name: 'Shooting');
        final c = evaluationContainer(on: true, evaluations: evals);
        await settled(c, clEvaluationTemplatesMasterProvider);
        await settled(c, clDeletedEvaluationTemplatesProvider);

        final restored = await c
            .read(clEvaluationTemplatesMasterProvider.notifier)
            .restoreTemplate(2);
        await settled(c, clDeletedEvaluationTemplatesProvider);

        expect(restored.name, 'Shooting -- Restored #1');
        expect(_names(c), isEmpty);
        expect(
          c.read(clEvaluationTemplatesMasterProvider).requireValue[2]!.name,
          'Shooting -- Restored #1',
        );
      },
    );
  });
}
