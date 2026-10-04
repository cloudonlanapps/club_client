import 'package:cl_club_members/src/utils/admin_group_actions.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

Group _group({
  GroupKind kind = GroupKind.manual,
  DateTime? deletedAtUtc,
}) {
  return Group(
    id: 1,
    name: 'g',
    kind: kind,
    createdAtUtc: DateTime.utc(2024),
    deletedAtUtc: deletedAtUtc,
  );
}

void main() {
  group('groupAdminActionsFor', () {
    List<String> keys(List<GroupAdminAction> actions) =>
        actions.map((a) => a.key).toList();

    test('Issue 269: active group surfaces Rename and Delete', () {
      final actions = groupAdminActionsFor(_group(), isSuperAdmin: false);
      expect(keys(actions), ['rename', 'delete']);
      expect(actions.last.destructive, isTrue);
    });

    test(
      'Issue 269: super admin on active group still only sees Rename+Delete',
      () {
        final actions = groupAdminActionsFor(_group(), isSuperAdmin: true);
        expect(keys(actions), ['rename', 'delete']);
      },
    );

    test('Issue 269: deleted group surfaces Restore only for plain admin', () {
      final actions = groupAdminActionsFor(
        _group(deletedAtUtc: DateTime.utc(2025)),
        isSuperAdmin: false,
      );
      expect(keys(actions), ['restore']);
    });

    test(
      'Issue 269: deleted group surfaces Restore + Hard Delete for super',
      () {
        final actions = groupAdminActionsFor(
          _group(deletedAtUtc: DateTime.utc(2025)),
          isSuperAdmin: true,
        );
        expect(keys(actions), ['restore', 'hardDelete']);
        expect(actions.last.destructive, isTrue);
      },
    );
  });
}
