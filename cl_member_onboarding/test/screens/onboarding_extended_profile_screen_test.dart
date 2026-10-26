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
);

class _StubAuth extends AuthNotifier {
  _StubAuth(this._user);
  final UserPrivate _user;

  @override
  Future<UserPrivate?> build() async => _user;
}

const Key _sectionsKey = ValueKey('sections');

Widget _screen({
  required UserPrivate user,
  bool extendedProfile = true,
  VoidCallback? onContinue,
  List<UserPrivate>? built,
}) => ProviderScope(
  overrides: [
    authStateProvider.overrideWith(() => _StubAuth(user)),
    capabilitiesProvider.overrideWith(
      (ref) async => Capabilities(extendedProfile: extendedProfile),
    ),
  ],
  child: ShadApp(
    home: Scaffold(
      body: OnboardingExtendedProfileScreen(
        sections: (u) {
          built?.add(u);
          return const SizedBox(key: _sectionsKey, height: 10);
        },
        onContinue: onContinue ?? () {},
        onHome: () {},
      ),
    ),
  ),
);

void main() {
  group('Issue 320: OnboardingExtendedProfileScreen', () {
    testWidgets('Issue 320: a pending member gets the sections for '
        'themselves, said to be optional, and Continue', (tester) async {
      final built = <UserPrivate>[];
      var continued = 0;
      final user = _user(UserStatus.pending);
      await tester.pumpWidget(
        _screen(user: user, built: built, onContinue: () => continued++),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(_sectionsKey), findsOneWidget);
      expect(built.last.username, user.username);
      expect(find.textContaining('optional'), findsWidgets);

      await tester.tap(find.widgetWithText(ShadButton, 'Continue'));
      expect(continued, 1);
    });

    testWidgets('Issue 320: it is not available while the extended profile '
        'is off', (tester) async {
      await tester.pumpWidget(
        _screen(user: _user(UserStatus.pending), extendedProfile: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('Not available'), findsOneWidget);
      expect(find.byKey(_sectionsKey), findsNothing);
    });

    testWidgets('Issue 320: it is not available to a registered user', (
      tester,
    ) async {
      await tester.pumpWidget(_screen(user: _user(UserStatus.registered)));
      await tester.pumpAndSettle();

      expect(find.text('Not available'), findsOneWidget);
    });
  });

  group('Issue 320: the waiting page offers the step', () {
    Widget welcome({required bool extendedProfile, VoidCallback? onAdd}) =>
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              () => _StubAuth(_user(UserStatus.pending)),
            ),
            capabilitiesProvider.overrideWith(
              (ref) async => Capabilities(extendedProfile: extendedProfile),
            ),
          ],
          child: ShadApp(
            home: Scaffold(
              body: OnboardingWelcomeScreen(
                onContinue: () {},
                onHome: () {},
                onAddProfileDetails: onAdd,
              ),
            ),
          ),
        );

    testWidgets('Issue 320: with the extended profile on, the waiting page '
        'opens the step', (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        welcome(extendedProfile: true, onAdd: () => opened++),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add profile details'));
      expect(opened, 1);
    });

    testWidgets('Issue 320: with it off, there is no such button', (
      tester,
    ) async {
      await tester.pumpWidget(welcome(extendedProfile: false, onAdd: () {}));
      await tester.pumpAndSettle();

      expect(find.text('Add profile details'), findsNothing);
      expect(find.text('Back to sign in'), findsOneWidget);
    });
  });
}
