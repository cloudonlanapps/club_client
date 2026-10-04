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

class _StubSiteMedia extends ClSiteMediaMasterNotifier {
  @override
  Future<Map<String, MediaRef>> build() async => const {};
}

Widget _wrap(UserPrivate user) => ProviderScope(
  overrides: [
    authStateProvider.overrideWith(() => _StubAuth(user)),
    clSiteMediaMasterProvider.overrideWith(_StubSiteMedia.new),
  ],
  child: ShadApp(
    home: Scaffold(body: SiteMediaScreen(onHome: () {})),
  ),
);

void main() {
  group('Issue 19: SiteMediaScreen gating', () {
    testWidgets('Issue 19: an admin who is not super-admin is denied', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_user()));
      await tester.pumpAndSettle();
      expect(find.text('Access Denied'), findsOneWidget);
    });

    testWidgets('Issue 19: a super-admin sees the slots', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(_wrap(_user(superAdmin: true)));
      await tester.pumpAndSettle();
      expect(find.text('Access Denied'), findsNothing);
      expect(find.text('Website media'), findsOneWidget);
      expect(find.text('Landing background'), findsOneWidget);
    });
  });
}
