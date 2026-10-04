import 'package:cl_club_members/src/models/group_list_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GroupListFilter', () {
    test('default values', () {
      const filter = GroupListFilter();

      expect(filter.searchTerm, isNull);
      expect(filter.showDeleted, isFalse);
      expect(filter.typeFilter, GroupTypeFilter.all);
    });

    test('copyWith updates searchTerm', () {
      const filter = GroupListFilter();
      final updated = filter.copyWith(searchTerm: () => 'test');

      expect(updated.searchTerm, 'test');
      expect(updated.showDeleted, isFalse);
      expect(updated.typeFilter, GroupTypeFilter.all);
    });

    test('copyWith clears searchTerm to null', () {
      final filter = const GroupListFilter().copyWith(
        searchTerm: () => 'test',
      );

      final cleared = filter.copyWith(searchTerm: () => null);

      expect(cleared.searchTerm, isNull);
    });

    test('copyWith updates showDeleted', () {
      const filter = GroupListFilter();
      final updated = filter.copyWith(showDeleted: true);

      expect(updated.showDeleted, isTrue);
    });

    test('copyWith updates typeFilter', () {
      const filter = GroupListFilter();
      final updated = filter.copyWith(typeFilter: GroupTypeFilter.auto);

      expect(updated.typeFilter, GroupTypeFilter.auto);
    });

    test('equality', () {
      const a = GroupListFilter();
      const b = GroupListFilter();
      final c = const GroupListFilter().copyWith(showDeleted: true);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is consistent with equality', () {
      const a = GroupListFilter();
      const b = GroupListFilter();

      expect(a.hashCode, b.hashCode);
    });

    test('toString includes all fields', () {
      const filter = GroupListFilter();

      expect(
        filter.toString(),
        contains('GroupListFilter'),
      );
      expect(filter.toString(), contains('searchTerm'));
      expect(filter.toString(), contains('showDeleted'));
      expect(filter.toString(), contains('typeFilter'));
    });
  });
}
