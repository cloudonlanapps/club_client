import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart';

const EvaluationItemValue _copy = EvaluationItemValue(
  id: 12,
  kind: EvaluationItemKind.singleChoice,
  text: 'Edges',
  originItemId: 7,
  choices: [EvaluationChoice(value: 'inside', text: 'Inside')],
);

void main() {
  group('Issue 173: EvaluationItemValue.originItemId', () {
    test('Issue 173: defaults to null', () {
      expect(
        const EvaluationItemValue(kind: EvaluationItemKind.qa).originItemId,
        isNull,
      );
    });

    test('Issue 173: round-trips through toMap / fromMap and JSON', () {
      expect(EvaluationItemValue.fromMap(_copy.toMap()), _copy);
      expect(EvaluationItemValue.fromJson(_copy.toJson()), _copy);
      expect(_copy.toMap()['originItemId'], 7);
    });

    test('Issue 173: copyWith sets and clears it', () {
      expect(_copy.copyWith(originItemId: () => 9).originItemId, 9);
      expect(_copy.copyWith(originItemId: () => null).originItemId, isNull);
      expect(_copy.copyWith(text: 'x').originItemId, 7);
    });

    test('Issue 173: takes part in equality, hashCode and toString', () {
      final other = _copy.copyWith(originItemId: () => 8);
      expect(other, isNot(_copy));
      expect(_copy.copyWith(), _copy);
      expect(_copy.copyWith().hashCode, _copy.hashCode);
      expect(_copy.toString(), contains('originItemId: 7'));
    });
  });
}
