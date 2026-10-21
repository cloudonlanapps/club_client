import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_zone/cl_member_zone.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

UserPrivate _user({UserRoles roles = const UserRoles()}) => UserPrivate(
  username: 'm1',
  displayName: 'Plain Member',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: roles,
  createdAtUtc: DateTime.utc(2024),
);

class _StubAuth extends AuthNotifier {
  _StubAuth(this._user);
  final UserPrivate? _user;

  @override
  Future<UserPrivate?> build() async => _user;
}

/// Pumps [screen] for [user] and reports whether it was refused. The
/// screens are not given their data: a refusal must come before any load.
Future<bool> _refused(
  WidgetTester tester,
  Widget screen, {
  required UserPrivate user,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authStateProvider.overrideWith(() => _StubAuth(user))],
      child: ShadApp(home: Scaffold(body: screen)),
    ),
  );
  await tester.pump();
  await tester.pump();
  return find.text(AccessDeniedView.title).evaluate().isNotEmpty;
}

void _noop() {}

void main() {
  final member = _user();
  final coach = _user(roles: const UserRoles(isCoach: true));

  group('Issue 203: staff screens refuse a plain member', () {
    final adminOnly = <String, Widget>{
      'GroupCreateScreen': const GroupCreateScreen(
        onCreated: _noop,
        onCancel: _noop,
        onHome: _noop,
      ),
      'UserCreateScreen': const UserCreateScreen(
        onCreated: _noop,
        onCancel: _noop,
        onHome: _noop,
      ),
      'VenueCreateScreen': const VenueCreateScreen(
        onCreated: _noop,
        onCancel: _noop,
        onHome: _noop,
      ),
    };
    final staff = <String, Widget>{
      'AdminGroupProfileScreen': const AdminGroupProfileScreen(
        groupId: 1,
        onOpenRequests: _noop,
        onOpenAllMembers: _noop,
        onDeleted: _noop,
        onHome: _noop,
      ),
      'GroupMembersScreen': const GroupMembersScreen(
        groupId: 1,
        onRemoved: _noop,
        onHome: _noop,
      ),
      'AdminUserProfileScreen': AdminUserProfileScreen(
        targetUsername: 'someone',
        onReview: _noop,
        eventsSection: (_) => const SizedBox.shrink(),
        onHome: _noop,
      ),
      'AdminUserReviewScreen': const AdminUserReviewScreen(
        username: 'someone',
        onBack: _noop,
        onHome: _noop,
      ),
      'VenuesScreen': VenuesScreen(
        onVenueTap: (_) {},
        onCreateVenue: _noop,
        onHome: _noop,
      ),
      'VenueProfileScreen': const VenueProfileScreen(
        venueId: 1,
        onDeleted: _noop,
        onHome: _noop,
      ),
    };

    for (final entry in {...adminOnly, ...staff}.entries) {
      testWidgets('Issue 203: ${entry.key} refuses a plain member', (
        tester,
      ) async {
        expect(await _refused(tester, entry.value, user: member), isTrue);
      });
    }

    for (final entry in adminOnly.entries) {
      testWidgets('Issue 203: ${entry.key} refuses a coach', (tester) async {
        expect(await _refused(tester, entry.value, user: coach), isTrue);
      });
    }

    testWidgets('Issue 203: VenuesScreen lets a coach in', (tester) async {
      expect(
        await _refused(tester, staff['VenuesScreen']!, user: coach),
        isFalse,
      );
    });
  });
}
