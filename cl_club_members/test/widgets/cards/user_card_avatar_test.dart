import 'package:cl_club_members/src/widgets/cards/user_card.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClUsersMasterNotifier, avatarImageProvider, clUsersMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this._user);
  final UserPrivate? _user;
  @override
  Future<UserPrivate?> build() async => _user;
}

class _StubUsersMasterNotifier extends ClUsersMasterNotifier {
  _StubUsersMasterNotifier(this._users);
  final Map<String, UserInfo> _users;
  @override
  Future<Map<String, UserInfo>> build() async => _users;
}

UserPrivate _admin() => UserPrivate(
  username: 'admin1',
  displayName: 'Admin',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(isAdmin: true),
  createdAtUtc: DateTime.utc(2024),
);

UserInfo _member() => const UserInfo(
  username: 'activeguy',
  displayName: 'Active Guy',
  firstName: 'Active',
  lastName: 'Guy',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: UserRoles(),
);

Widget _wrap({required UserInfo user, required String? avatarUrl}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith(() => _StubAuthNotifier(_admin())),
      clUsersMasterProvider.overrideWith(
        () => _StubUsersMasterNotifier({user.username: user}),
      ),
      avatarImageProvider(user.username).overrideWith((_) async => avatarUrl),
    ],
    child: ShadApp(
      home: Scaffold(body: UserCard(username: user.username)),
    ),
  );
}

void main() {
  testWidgets(
    'Issue 710: user list card renders the uploaded avatar when a URL is '
    'available',
    (tester) async {
      const url = 'https://api.example.test/media/by_id/abc/download';
      final user = _member();
      await tester.pumpWidget(_wrap(user: user, avatarUrl: url));
      await tester.pumpAndSettle();

      final image = find.byType(CredentialedNetworkImage);
      expect(image, findsOneWidget);
      expect(
        tester.widget<CredentialedNetworkImage>(image).imageUrl,
        url,
      );
      // No initials fallback while a real image is shown.
      expect(find.text('AG'), findsNothing);
    },
  );

  testWidgets(
    'Issue 710: user list card falls back to initials when there is no '
    'avatar',
    (tester) async {
      final user = _member();
      await tester.pumpWidget(_wrap(user: user, avatarUrl: null));
      await tester.pumpAndSettle();

      expect(find.byType(CredentialedNetworkImage), findsNothing);
      expect(find.text('AG'), findsOneWidget);
    },
  );
}
