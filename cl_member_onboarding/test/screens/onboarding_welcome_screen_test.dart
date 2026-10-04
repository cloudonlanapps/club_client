import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_onboarding/cl_member_onboarding.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
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

Widget _harness({
  required UserPrivate user,
  Future<Capabilities> Function()? capabilities,
}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith(() => _StubAuth(user)),
      capabilitiesProvider.overrideWith(
        (ref) => (capabilities ?? () async => const Capabilities())(),
      ),
    ],
    child: ShadApp(
      home: Scaffold(
        body: OnboardingWelcomeScreen(
          onContinue: () {},
          onHome: () {},
        ),
      ),
    ),
  );
}

void main() {
  group('Issue 433: OnboardingWelcomeScreen gate', () {
    testWidgets('allows pending users', (tester) async {
      await tester.pumpWidget(
        _harness(
          user: _user(status: UserStatus.pending),
        ),
      );
      await tester.pumpAndSettle();
      // Pending variant renders the SubmittedConfirmation card with this CTA.
      expect(find.text('Back to sign in'), findsOneWidget);
      expect(find.text('Not available'), findsNothing);
    });

    testWidgets('denies active users with ErrorView', (tester) async {
      await tester.pumpWidget(
        _harness(
          user: _user(status: UserStatus.active),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Not available'), findsOneWidget);
    });

    testWidgets('allows registered users with a note (reapply variant)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          user: _user(
            status: UserStatus.registered,
            adminReviewNote: 'please fix x',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Not available'), findsNothing);
      expect(find.text('Could not load this page'), findsNothing);
    });

    testWidgets('allows registered users with no note (intro variant)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          user: _user(status: UserStatus.registered),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Not available'), findsNothing);
      expect(find.text('Welcome aboard - almost!'), findsOneWidget);
    });
  });

  group('Issue 84: the welcome step follows identity verification', () {
    testWidgets('on: Continue leads to the document step', (tester) async {
      await tester.pumpWidget(
        _harness(user: _user(status: UserStatus.registered)),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ShadButton, 'Continue'), findsOneWidget);
      expect(find.textContaining('identity document'), findsOneWidget);
    });

    testWidgets('off: the step submits for review, with no document', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          user: _user(status: UserStatus.registered),
          capabilities: () async =>
              const Capabilities(identityVerification: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(ShadButton, 'Submit for review'),
        findsOneWidget,
      );
      expect(find.textContaining('document'), findsNothing);
    });

    testWidgets('an unreadable capability offers a retry, not a guess', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          user: _user(status: UserStatus.registered),
          capabilities: () async => throw Exception('offline'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Could not load this page'), findsOneWidget);
      expect(find.text('Welcome aboard - almost!'), findsNothing);
    });

    testWidgets('a pending user does not wait for the capability', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          user: _user(status: UserStatus.pending),
          capabilities: () async => throw Exception('offline'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Back to sign in'), findsOneWidget);
    });
  });
}
