import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_onboarding/cl_member_onboarding.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

UserPrivate _user(UserStatus status) => UserPrivate(
  username: 'u1',
  displayName: 'U One',
  status: status,
  isSuperAdmin: false,
  roles: const UserRoles(),
  createdAtUtc: DateTime.utc(2024),
  email: 'u1@example.com',
);

class _StubAuth extends AuthNotifier {
  _StubAuth(this._user);
  final UserPrivate _user;

  @override
  Future<UserPrivate?> build() async => _user;
}

const _list = 'The published applications';

Future<List<String>> _pump(
  WidgetTester tester, {
  required UserStatus status,
  required bool applications,
}) async {
  final builtFor = <String>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => _StubAuth(_user(status))),
        capabilitiesProvider.overrideWith(
          (ref) async => Capabilities(applications: applications),
        ),
      ],
      child: ShadApp(
        home: Scaffold(
          body: OnboardingWelcomeScreen(
            onContinue: () {},
            onHome: () {},
            applications: (user) {
              builtFor.add(user.username);
              return const Text(_list);
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return builtFor;
}

void main() {
  group('Issue 321: the waiting page lists the published applications', () {
    testWidgets('Issue 321: shown to a pending member while applications '
        'are on', (tester) async {
      final builtFor = await _pump(
        tester,
        status: UserStatus.pending,
        applications: true,
      );
      expect(find.text(_list), findsOneWidget);
      expect(find.text('Back to sign in'), findsOneWidget);
      expect(builtFor.last, 'u1');
    });

    testWidgets('Issue 321: not while applications are off', (tester) async {
      final builtFor = await _pump(
        tester,
        status: UserStatus.pending,
        applications: false,
      );
      expect(find.text(_list), findsNothing);
      expect(builtFor, isEmpty);
    });

    testWidgets('Issue 321: not before the member has applied', (
      tester,
    ) async {
      final builtFor = await _pump(
        tester,
        status: UserStatus.registered,
        applications: true,
      );
      expect(find.text(_list), findsNothing);
      expect(builtFor, isEmpty);
    });
  });
}
