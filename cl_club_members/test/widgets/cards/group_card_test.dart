import 'package:cl_club_members/src/widgets/cards/group_card.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionItem, EntityImage;

class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this._user);
  final UserPrivate? _user;
  @override
  Future<UserPrivate?> build() async => _user;
}

class _StubGroupsMasterNotifier extends ClGroupsMasterNotifier {
  _StubGroupsMasterNotifier(this._groups);
  final Map<int, Group> _groups;
  @override
  Future<Map<int, Group>> build() async => _groups;
}

UserPrivate _admin() => UserPrivate(
  username: 'admin',
  displayName: 'Admin',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(isAdmin: true),
  createdAtUtc: DateTime.utc(2024),
);

Group _group({bool active = true, GroupKind kind = GroupKind.manual}) => Group(
  id: 7,
  name: 'Alpha',
  kind: kind,
  createdAtUtc: DateTime.utc(2025),
  deletedAtUtc: active ? null : DateTime.utc(2025, 6),
);

Future<void> _pumpCard(
  WidgetTester tester, {
  required Group group,
  VoidCallback? onManageMembers,
  List<ActionItem>? trailing,
  String? imageUrl,
  double width = 360,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => _StubAuthNotifier(_admin())),
        clGroupsMasterProvider.overrideWith(
          () => _StubGroupsMasterNotifier({group.id: group}),
        ),
        groupImageProvider(group.id).overrideWith((ref) async => imageUrl),
      ],
      child: ShadApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            child: GroupCard(
              groupId: group.id,
              onManageMembers: onManageMembers,
              trailing: trailing,
            ),
          ),
        ),
      ),
    ),
  );
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('Issue 501: GroupCard routes actions through trailingActions', () {
    testWidgets(
      'Issue 501: deleted group surfaces Restore via the typed slot',
      (tester) async {
        await _pumpCard(tester, group: _group(active: false));
        expect(find.text('Restore'), findsOneWidget);
      },
    );

    testWidgets(
      'Issue 501: active manual group surfaces Manage Members when wired '
      'and fires it at mobile width',
      (tester) async {
        var managed = false;
        await _pumpCard(
          tester,
          group: _group(),
          onManageMembers: () => managed = true,
        );

        expect(find.text('Manage Members'), findsOneWidget);
        await tester.tap(find.text('Manage Members'));
        await tester.pump();
        expect(managed, isTrue);
      },
    );

    testWidgets(
      'Issue 501: bespoke trailing list renders through trailingActions',
      (tester) async {
        var removed = false;
        await _pumpCard(
          tester,
          group: _group(),
          trailing: [
            ActionItem(label: 'Remove', onPressed: () => removed = true),
          ],
        );

        expect(find.text('Remove'), findsOneWidget);
        await tester.tap(find.text('Remove'));
        await tester.pump();
        expect(removed, isTrue);
      },
    );
  });

  group('Issue 625: active GroupCard drops Edit and Delete', () {
    testWidgets(
      'Issue 625: active group with no manage-members callback shows no '
      'actions (no Edit, no Delete)',
      (tester) async {
        await _pumpCard(tester, group: _group());
        expect(find.text('Edit'), findsNothing);
        expect(find.text('Delete'), findsNothing);
        expect(find.text('Manage Members'), findsNothing);
      },
    );

    testWidgets(
      'Issue 625: active group with manage-members still shows neither '
      'Edit nor Delete',
      (tester) async {
        await _pumpCard(
          tester,
          group: _group(),
          onManageMembers: () {},
        );
        expect(find.text('Manage Members'), findsOneWidget);
        expect(find.text('Edit'), findsNothing);
        expect(find.text('Delete'), findsNothing);
      },
    );
  });

  group('Issue 711: GroupCard shows the hero image in the list', () {
    testWidgets(
      'Issue 711: renders the group image when one is available',
      (tester) async {
        await _pumpCard(
          tester,
          group: _group(),
          imageUrl: 'https://example.test/group-7.png',
        );
        final image = tester.widget<EntityImage>(find.byType(EntityImage));
        expect(image.imageUrl, 'https://example.test/group-7.png');
      },
    );

    testWidgets(
      'Issue 711: falls back to the placeholder when there is no image',
      (tester) async {
        await _pumpCard(tester, group: _group());
        final image = tester.widget<EntityImage>(find.byType(EntityImage));
        expect(image.imageUrl, isNull);
      },
    );
  });
}
