import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show GroupFormValidators, GroupMode;

void main() {
  group('GroupFormValidators.name', () {
    test('rejects empty / whitespace', () {
      expect(GroupFormValidators.name(''), isNotNull);
      expect(GroupFormValidators.name('  '), isNotNull);
    });

    test('accepts non-empty', () {
      expect(GroupFormValidators.name('U12 Boys'), isNull);
    });

    test('Issue 676: requires at least 2 characters (shared name rule)', () {
      expect(GroupFormValidators.name('A'), isNotNull);
      expect(GroupFormValidators.name('U8'), isNull);
    });
  });

  group('GroupFormValidators.dobRange', () {
    test('null when either bound is null', () {
      expect(GroupFormValidators.dobRange(null, DateTime.utc(2016)), isNull);
      expect(GroupFormValidators.dobRange(DateTime.utc(2010), null), isNull);
    });

    test('rejects onOrAfter after onOrBefore', () {
      expect(
        GroupFormValidators.dobRange(DateTime.utc(2016), DateTime.utc(2010)),
        isNotNull,
      );
    });

    test('accepts onOrAfter <= onOrBefore', () {
      final after = DateTime.utc(2010);
      final before = DateTime.utc(2016, 12, 31);
      expect(GroupFormValidators.dobRange(after, before), isNull);
      expect(GroupFormValidators.dobRange(after, after), isNull);
    });
  });

  group('GroupFormValidators.criteriaForMode', () {
    test('manual mode never requires criteria', () {
      expect(
        GroupFormValidators.criteriaForMode(
          GroupMode.manual,
          hasAnyCriterion: false,
        ),
        isNull,
      );
    });

    test('auto / semi-auto require at least one criterion', () {
      expect(
        GroupFormValidators.criteriaForMode(
          GroupMode.auto,
          hasAnyCriterion: false,
        ),
        isNotNull,
      );
      expect(
        GroupFormValidators.criteriaForMode(
          GroupMode.semiAuto,
          hasAnyCriterion: false,
        ),
        isNotNull,
      );
    });

    test('auto / semi-auto pass when a criterion is set', () {
      expect(
        GroupFormValidators.criteriaForMode(
          GroupMode.auto,
          hasAnyCriterion: true,
        ),
        isNull,
      );
    });
  });
}
