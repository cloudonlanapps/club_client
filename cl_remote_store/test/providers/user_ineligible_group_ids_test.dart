import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

/// The staff read behind the Groups section of a member's profile
/// (club_client#43): the groups the member no longer matches.

const _member = 'workflow_member';

class _FakeGroups extends Fake implements GroupSource {
  _FakeGroups(this.mine, this.members);

  final List<Group> mine;
  final Map<int, List<GroupMember>> members;
  final List<int> memberReads = [];

  @override
  Future<List<Group>> getMyGroups(String username) async => mine;

  @override
  Future<List<GroupMember>> getMembers(
    int groupId, {
    String? sortBy,
    bool? descending,
  }) async {
    memberReads.add(groupId);
    return members[groupId] ?? const [];
  }
}

Group _group(
  int id, {
  GroupKind kind = GroupKind.semiAuto,
  int ineligibleMemberCount = 0,
}) => Group(
  id: id,
  name: 'workflow_group_$id',
  kind: kind,
  ineligibleMemberCount: ineligibleMemberCount,
  createdAtUtc: DateTime.utc(2025),
);

ProviderContainer _container({required GroupSource groups}) {
  final container = ProviderContainer(
    overrides: [
      secureClientProvider.overrideWith(
        (ref) async => fakeSecureClient(groups: groups),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('Issue 43: clUserIneligibleGroupIdsProvider', () {
    test('Issue 43: names the semi-auto group whose member list marks the '
        'member as not eligible', () async {
      final source = _FakeGroups(
        [_group(1, ineligibleMemberCount: 1), _group(2)],
        {
          1: const [
            GroupMember(membername: 'workflow_other'),
            GroupMember(membername: _member, eligible: false),
          ],
        },
      );
      final container = _container(groups: source);

      final ids = await container.read(
        clUserIneligibleGroupIdsProvider(_member).future,
      );

      expect(ids, {1});
    });

    test('Issue 43: a group whose ineligible member is someone else is not '
        'named', () async {
      final container = _container(
        groups: _FakeGroups(
          [_group(1, ineligibleMemberCount: 1)],
          {
            1: const [
              GroupMember(membername: 'workflow_other', eligible: false),
              GroupMember(membername: _member),
            ],
          },
        ),
      );

      final ids = await container.read(
        clUserIneligibleGroupIdsProvider(_member).future,
      );

      expect(ids, isEmpty);
    });

    test('Issue 43: reads the member list only of semi-auto groups that '
        'count an ineligible member', () async {
      final source = _FakeGroups(
        [
          _group(1),
          _group(2, kind: GroupKind.manual),
          _group(3, kind: GroupKind.auto),
          _group(4, ineligibleMemberCount: 2),
        ],
        {
          4: const [GroupMember(membername: _member, eligible: false)],
        },
      );
      final container = _container(groups: source);

      final ids = await container.read(
        clUserIneligibleGroupIdsProvider(_member).future,
      );

      expect(ids, {4});
      expect(source.memberReads, [4]);
    });
  });
}
