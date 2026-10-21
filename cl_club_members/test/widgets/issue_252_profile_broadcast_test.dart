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

final Finder _broadcastButton = find.byTooltip('Broadcast');

/// Mounts [target]'s profile for [viewer]; returns how often the Broadcast
/// button opened the screen.
Future<List<int>> _pump(
  WidgetTester tester, {
  required UserPrivate viewer,
  UserPrivate? target,
}) async {
  final shown = target ?? _user('member_a');
  final opened = <int>[];
  await tester.binding.setSurfaceSize(const Size(1200, 4000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clUserPrivateProvider(shown.username).overrideWith((_) async => shown),
        clUserInfoProvider(shown.username).overrideWith((_) async => shown),
        authStateProvider.overrideWith(() => _Auth(viewer)),
        avatarImageProvider(shown.username).overrideWith((_) async => null),
        evaluationsProvider.overrideWithValue(false),
        clEvaluationTemplatesMasterProvider.overrideWith(_Templates.new),
        clEventsMasterProvider.overrideWith(_Events.new),
      ],
      child: ShadApp(
        home: Scaffold(
          body: UserProfileView(
            targetUsername: shown.username,
            onBroadcast: () => opened.add(1),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return opened;
}

void main() {
  group("Issue 252: the Broadcast button on a member's profile", () {
    testWidgets('Issue 252: an admin sees it and it opens the one-to-one '
        'screen', (tester) async {
      final opened = await _pump(tester, viewer: _user('admin_a', admin: true));

      expect(_broadcastButton, findsOneWidget);
      await tester.tap(_broadcastButton);
      await tester.pump();
      expect(opened, hasLength(1));
    });

    testWidgets('Issue 252: a coach who is not an admin does not', (
      tester,
    ) async {
      await _pump(tester, viewer: _user('coach_a', coach: true));
      expect(_broadcastButton, findsNothing);
    });

    testWidgets('Issue 252: not on your own profile', (tester) async {
      final admin = _user('admin_a', admin: true);
      await _pump(tester, viewer: admin, target: admin);
      expect(_broadcastButton, findsNothing);
    });

    testWidgets('Issue 252: not for a member who is not active', (
      tester,
    ) async {
      await _pump(
        tester,
        viewer: _user('admin_a', admin: true),
        target: _user('member_a', status: UserStatus.blocked),
      );
      expect(_broadcastButton, findsNothing);
    });
  });
}
