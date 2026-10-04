import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_zone/cl_member_zone.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

UserPrivate _user({bool superAdmin = false}) => UserPrivate(
  username: 'u1',
  displayName: 'Test User',
  status: UserStatus.active,
  isSuperAdmin: superAdmin,
  roles: const UserRoles(isAdmin: true),
  createdAtUtc: DateTime.utc(2024),
);

class _StubAuth extends AuthNotifier {
  _StubAuth(this._u);
  final UserPrivate? _u;
  @override
  Future<UserPrivate?> build() async => _u;
}

class _StubClubIdentity extends ClClubIdentityMasterNotifier {
  @override
  Future<ClubIdentity> build() async => const ClubIdentity(name: 'Stub Club');
}

Widget _wrap(UserPrivate user) => ProviderScope(
  overrides: [
    authStateProvider.overrideWith(() => _StubAuth(user)),
    clClubIdentityMasterProvider.overrideWith(_StubClubIdentity.new),
  ],
  child: ShadApp(
    home: Scaffold(body: ClubIdentityScreen(onHome: () {})),
  ),
);

void main() {
  group('Issue 20: ClubIdentityScreen gating', () {
    testWidgets('Issue 20: an admin who is not super-admin is denied', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_user()));
      await tester.pumpAndSettle();
      expect(find.text('Access Denied'), findsOneWidget);
      expect(find.text('Stub Club'), findsNothing);
    });

    testWidgets('Issue 20: a super-admin sees the club details', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1100, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap(_user(superAdmin: true)));
      await tester.pumpAndSettle();
      expect(find.text('Access Denied'), findsNothing);
      expect(find.text('Club details'), findsOneWidget);
      expect(find.text('Stub Club'), findsOneWidget);
    });
  });
}
