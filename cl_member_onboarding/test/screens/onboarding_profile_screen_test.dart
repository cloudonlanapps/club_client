import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_onboarding/cl_member_onboarding.dart';
import 'package:cl_member_onboarding/src/models/onboarding_gate.dart';
import 'package:cl_member_onboarding/src/views/onboarding_profile_view.dart';
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

const Key _profileKey = ValueKey('profile');
const Key _extendedKey = ValueKey('extended');
const Key _applicationsKey = ValueKey('applications');

/// Stands in for the host's cards: the extended ones only while the
/// extended profile is on, as `OwnProfileCards` does.
class _Cards extends ConsumerWidget {
  const _Cards();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    children: [
      const SizedBox(key: _profileKey, height: 10),
      if (ref.watch(extendedProfileProvider) == true)
        const SizedBox(key: _extendedKey, height: 10),
    ],
  );
}

Widget _screen({
  required UserPrivate user,
  bool? extendedProfile = true,
  bool? applications = true,
  List<UserPrivate>? built,
}) => ProviderScope(
  overrides: [
    authStateProvider.overrideWith(() => _StubAuth(user)),
    extendedProfileProvider.overrideWithValue(extendedProfile),
    applicationsProvider.overrideWithValue(applications),
  ],
  child: ShadApp(
    home: Scaffold(
      body: OnboardingProfileScreen(
        profile: (u) {
          built?.add(u);
          return const _Cards();
        },
        applications: (u) => const SizedBox(key: _applicationsKey, height: 10),
        onHome: () {},
      ),
    ),
  ),
);

void main() {
  group('Issue 340: OnboardingProfileScreen', () {
    testWidgets('Issue 340: a pending member gets their own profile cards', (
      tester,
    ) async {
      final built = <UserPrivate>[];
      final user = _user(UserStatus.pending);
      await tester.pumpWidget(_screen(user: user, built: built));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingProfileView), findsOneWidget);
      expect(find.byKey(_profileKey), findsOneWidget);
      expect(built.last.username, user.username);
    });

    for (final flag in [true, false, null]) {
      testWidgets('Issue 340: the extended cards show only while the '
          'extended profile is on (here $flag)', (tester) async {
        await tester.pumpWidget(
          _screen(user: _user(UserStatus.pending), extendedProfile: flag),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(_profileKey), findsOneWidget);
        expect(
          find.byKey(_extendedKey),
          flag == true ? findsOneWidget : findsNothing,
        );
      });
    }

    testWidgets('Issue 340: the Applications section comes last while '
        'applications are on', (tester) async {
      await tester.pumpWidget(_screen(user: _user(UserStatus.pending)));
      await tester.pumpAndSettle();

      final body = tester.widget<Column>(
        find.byKey(OnboardingProfileView.bodyKey),
      );
      expect(body.children.last.key, _applicationsKey);
      expect(
        tester.getTopLeft(find.byKey(_applicationsKey)).dy,
        greaterThan(tester.getTopLeft(find.byKey(_extendedKey)).dy),
      );
    });

    for (final flag in [false, null]) {
      testWidgets('Issue 340: no Applications section while applications '
          'are $flag', (tester) async {
        await tester.pumpWidget(
          _screen(user: _user(UserStatus.pending), applications: flag),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(_profileKey), findsOneWidget);
        expect(find.byKey(_applicationsKey), findsNothing);
      });
    }

    for (final status in [UserStatus.registered, UserStatus.active]) {
      testWidgets('Issue 340: a ${status.name} member is refused', (
        tester,
      ) async {
        await tester.pumpWidget(_screen(user: _user(status)));
        await tester.pumpAndSettle();

        expect(find.byType(AccessDeniedView), findsOneWidget);
        expect(find.text(onboardingStepClosedMessage), findsOneWidget);
        expect(find.byKey(_profileKey), findsNothing);
      });
    }
  });

  group('Issue 340: the waiting page opens the profile page', () {
    Widget welcome({required bool extendedProfile, VoidCallback? onUpdate}) =>
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
                onUpdateProfile: onUpdate,
              ),
            ),
          ),
        );

    for (final extendedProfile in [true, false]) {
      testWidgets('Issue 340: Update profile shows and calls back with the '
          'extended profile ${extendedProfile ? 'on' : 'off'}', (
        tester,
      ) async {
        var opened = 0;
        await tester.pumpWidget(
          welcome(extendedProfile: extendedProfile, onUpdate: () => opened++),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(ShadButton, 'Update profile'));
        expect(opened, 1);
        expect(find.text('Back to sign in'), findsOneWidget);
      });
    }
  });
}
