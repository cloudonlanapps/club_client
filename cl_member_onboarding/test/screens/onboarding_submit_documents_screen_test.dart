import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_onboarding/cl_member_onboarding.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

UserPrivate _user({
  required UserStatus status,
  String? adminReviewNote,
}) {
  return UserPrivate(
    username: 'u1',
    displayName: 'U One',
    status: status,
    isSuperAdmin: false,
    roles: const UserRoles(),
    createdAtUtc: DateTime.utc(2024),
    adminReviewNote: adminReviewNote,
    email: 'u1@example.com',
  );
}

class _StubAuth extends AuthNotifier {
  _StubAuth(this._user);
  final UserPrivate _user;

  @override
  Future<UserPrivate?> build() async => _user;
}

Widget _harness({required UserPrivate user}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith(() => _StubAuth(user)),
    ],
    child: ShadApp(
      home: Scaffold(
        body: OnboardingSubmitDocumentsScreen(onHome: () {}),
      ),
    ),
  );
}

void main() {
  group('Issue 433: OnboardingSubmitDocumentsScreen gate', () {
    testWidgets('denies pending users with ErrorView', (tester) async {
      await tester.pumpWidget(
        _harness(
          user: _user(status: UserStatus.pending),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Not available'), findsOneWidget);
    });

    testWidgets('denies registered users with a note', (tester) async {
      await tester.pumpWidget(
        _harness(
          user: _user(
            status: UserStatus.registered,
            adminReviewNote: 'please fix x',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Not available'), findsOneWidget);
    });

    // Positive-path (gate passes) is exercised end-to-end via the host
    // app's integration tests — the view below the screen reaches for
    // `serverConfigProvider` which this widget-level harness doesn't
    // override, so we only assert the deny branches here.

    testWidgets('denies active users with ErrorView', (tester) async {
      await tester.pumpWidget(
        _harness(
          user: _user(status: UserStatus.active),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Not available'), findsOneWidget);
    });
  });
}
