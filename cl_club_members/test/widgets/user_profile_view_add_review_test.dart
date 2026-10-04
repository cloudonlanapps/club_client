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

UserPrivate _user(String username, {bool admin = false, bool coach = false}) =>
    UserPrivate(
      username: username,
      displayName: username,
      status: UserStatus.active,
      isSuperAdmin: false,
      roles: UserRoles(isAdmin: admin, isCoach: coach),
      createdAtUtc: DateTime.utc(2024, 6, 15),
    );

const _addReview = 'Add Review';

Future<void> _pump(
  WidgetTester tester, {
  required UserPrivate viewer,
  bool evaluations = true,
}) async {
  final target = _user('member_a');
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
        evaluationsProvider.overrideWithValue(evaluations),
        clEvaluationTemplatesMasterProvider.overrideWith(_Templates.new),
        clEventsMasterProvider.overrideWith(_Events.new),
      ],
      child: ShadApp(
        home: Scaffold(
          body: UserProfileView(
            targetUsername: target.username,
            onOpenReview: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group("Issue 174: Add Review on a member's profile", () {
    testWidgets('Issue 174: a coach sees Add Review and it opens the dialog', (
      tester,
    ) async {
      await _pump(tester, viewer: _user('coach_a', coach: true));
      expect(find.text(_addReview), findsOneWidget);
      await tester.tap(find.text(_addReview));
      await tester.pumpAndSettle();
      expect(find.text('Start a review'), findsOneWidget);
    });

    testWidgets('Issue 174: an admin who does not coach does not', (
      tester,
    ) async {
      await _pump(tester, viewer: _user('admin_a', admin: true));
      expect(find.text(_addReview), findsNothing);
    });

    testWidgets('Issue 174: a plain member does not', (tester) async {
      await _pump(tester, viewer: _user('member_b'));
      expect(find.text(_addReview), findsNothing);
    });

    testWidgets('Issue 174: nobody does with evaluations off', (tester) async {
      await _pump(
        tester,
        viewer: _user('coach_a', coach: true),
        evaluations: false,
      );
      expect(find.text(_addReview), findsNothing);
    });
  });
}
