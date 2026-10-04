import 'package:cl_club_evaluation/src/utils/evaluation_layout_sync.dart';
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart';

import '../support/evaluation_scope.dart';

const EvaluationItemValue _a = EvaluationItemValue(
  id: 1,
  kind: EvaluationItemKind.qa,
  text: 'A',
);
const EvaluationItemValue _b = EvaluationItemValue(
  id: 2,
  kind: EvaluationItemKind.qa,
  text: 'B',
);

const List<EvaluationLayoutEntry> _before = [
  EvaluationLayoutEntry.item(_a),
  EvaluationLayoutEntry.section(title: 'S', items: [_b]),
];

sdk.EvaluationTemplate _server() => template(
  7,
  layout: const [
    sdk.EvaluationLayoutItem(1),
    sdk.EvaluationLayoutSection('S', [2]),
  ],
  items: const [
    sdk.EvaluationQaItem(id: 1, question: 'A'),
    sdk.EvaluationQaItem(id: 2, question: 'B'),
  ],
);

Future<List<String>> _sync(List<EvaluationLayoutEntry> after) async {
  final stub = StubTemplates({7: _server()});
  await EvaluationLayoutSync.apply(
    templateId: 7,
    before: _before,
    after: after,
    notifier: stub,
  );
  return stub.calls;
}

void main() {
  group('Issue 173: EvaluationLayoutSync', () {
    test('Issue 173: a new item is added, into its section', () async {
      expect(
        await _sync([
          _before.first,
          const EvaluationLayoutEntry.section(
            title: 'S',
            items: [
              _b,
              EvaluationItemValue(kind: EvaluationItemKind.qa, text: 'C'),
            ],
          ),
        ]),
        ['add 7 qa S'],
      );
    });

    test('Issue 173: a removed item is removed', () async {
      expect(await _sync([_before.last]), ['remove 7 1']);
    });

    test('Issue 173: an edited item is replaced in place', () async {
      expect(
        await _sync([
          EvaluationLayoutEntry.item(_a.copyWith(text: 'A2')),
          _before.last,
        ]),
        ['replace 7 1'],
      );
    });

    test('Issue 173: a reorder or a new section re-lays it out', () async {
      expect(await _sync(_before.reversed.toList()), ['layout 7']);
      expect(
        await _sync([
          ..._before,
          const EvaluationLayoutEntry.section(title: 'New'),
        ]),
        ['layout 7'],
      );
    });

    test('Issue 173: no change makes no call', () async {
      expect(await _sync(_before), isEmpty);
    });
  });
}
