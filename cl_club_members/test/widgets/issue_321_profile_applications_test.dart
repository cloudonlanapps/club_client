import 'package:cl_club_members/src/views/user_profile_view.dart'
    show UserProfileView;
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        ClEvaluationTemplatesMasterNotifier,
        ClEventsMasterNotifier,
        avatarImageProvider,
        clEvaluationTemplatesMasterProvider,
        clEventsMasterProvider,
        clUserInfoProvider,
        clUserPrivateProvider,
        evaluationsProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class _Auth extends AuthNotifier {
  _Auth(this.user);
  final UserPrivate user;
  @override
  Future<UserPrivate?> build() async => user;
}

class _Templates extends ClEvaluationTemplatesMasterNotifier {
  @override
  Future<Map<int, EvaluationTemplate>> build() async => const {};
}

class _Events extends ClEventsMasterNotifier {
  @override
  Future<Map<int, Event>> build() async => const {};
}

UserPrivate _user(
  String username, {
  bool admin = false,
  bool coach = false,
  UserStatus status = UserStatus.active,
}) => UserPrivate(
  username: username,
  displayName: username,
  status: status,
  isSuperAdmin: false,
  roles: UserRoles(isAdmin: admin, isCoach: coach),
  createdAtUtc: DateTime.utc(2024, 6, 15),
);

/// What the injected Applications section was built for: the member and
/// whether they are the viewer.
typedef _Built = ({String member, bool own});

/// Mounts [target]'s profile for [viewer] with an injected Applications
/// section; returns what it was built for.
Future<List<_Built>> _pump(
  WidgetTester tester, {
  required UserPrivate viewer,
  required UserPrivate target,
}) async {
  final built = <_Built>[];
  await tester.binding.setSurfaceSize(const Size(1200, 4000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clUserPrivateProvider(
          target.username,
        ).overrideWith((_) async => target),
        clUserInfoProvider(target.username).overrideWith((_) async => target),
        authStateProvider.overrideWith(() => _Auth(viewer)),
        avatarImageProvider(target.username).overrideWith((_) async => null),
        evaluationsProvider.overrideWithValue(false),
        clEvaluationTemplatesMasterProvider.overrideWith(_Templates.new),
        clEventsMasterProvider.overrideWith(_Events.new),
      ],
      child: ShadApp(
        home: Scaffold(
          body: UserProfileView(
            targetUsername: target.username,
            applicationsSection: (member, {required own}) {
              built.add((member: member.username, own: own));
              return const Text('Applications section');
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return built;
}

void main() {
  group('Issue 321: the profile hosts the Applications section', () {
    testWidgets('Issue 321: on one’s own profile, as one’s own', (
      tester,
    ) async {
      final me = _user('member_a');
      final built = await _pump(tester, viewer: me, target: me);
      expect(find.text('Applications section'), findsOneWidget);
      expect(built.last, (member: 'member_a', own: true));
    });

    testWidgets('Issue 321: for an admin on a member’s profile, as that '
        'member’s', (tester) async {
      final built = await _pump(
        tester,
        viewer: _user('admin_a', admin: true),
        target: _user('member_a'),
      );
      expect(find.text('Applications section'), findsOneWidget);
      expect(built.last, (member: 'member_a', own: false));
    });

    testWidgets('Issue 321: not for a coach on someone else’s profile', (
      tester,
    ) async {
      final built = await _pump(
        tester,
        viewer: _user('coach_a', coach: true),
        target: _user('member_a'),
      );
      expect(find.text('Applications section'), findsNothing);
      expect(built, isEmpty);
    });
  });
}
