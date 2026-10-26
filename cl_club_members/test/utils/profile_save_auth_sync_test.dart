import 'package:cl_club_members/src/utils/admin_user_profile_saves.dart';
import 'package:cl_club_members/src/utils/apply_user_update.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClUsersMasterNotifier, clUsersMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

UserPrivate _user(String username, {bool isAdmin = false, String? bio}) =>
    UserPrivate(
      username: username,
      displayName: username,
      status: UserStatus.active,
      isSuperAdmin: false,
      roles: UserRoles(isAdmin: isAdmin),
      bio: bio,
      createdAtUtc: DateTime.utc(2024, 6, 15),
    );

/// The signed-in admin. Each build is a session restore; [builds] counts
/// them.
class _Auth extends AuthNotifier {
  int builds = 0;

  @override
  Future<UserPrivate?> build() async {
    builds++;
    return _user('admin1', isAdmin: true);
  }
}

/// Answers every update with the user carrying the new bio.
class _Users extends ClUsersMasterNotifier {
  @override
  Future<Map<String, UserInfo>> build() async => {};

  @override
  Future<UserPrivate> updateUser(
    String username, {
    String? email,
    String? Function()? firstName,
    String? Function()? middleName,
    String? Function()? lastName,
    String? Function()? phone,
    DateTime? Function()? dateOfBirthUtc,
    String? Function()? bio,
    String? Function()? achievements,
    String? Function()? emergencyContact,
    String? Function()? medicalNotes,
    String? Function()? nickname,
    bool? useNamePublicly,
    Gender? Function()? gender,
    Address? Function()? address,
    bool? isPublicProfile,
    String? Function()? clubDistrict,
    String? Function()? preferredPosition,
    String? Function()? pastExperience,
    String? Function()? nationality,
    String? Function()? preferredLanguage,
    Guardian? Function()? guardian,
    DateTime? Function()? membershipDateUtc,
  }) async => _user(
    username,
    isAdmin: username == 'admin1',
    bio: bio?.call(),
  );
}

/// Pumps a button that runs [save], taps it, and returns the auth stub.
Future<_Auth> _runSave(
  WidgetTester tester,
  Future<void> Function(WidgetRef ref, BuildContext context) save,
) async {
  final auth = _Auth();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => auth),
        clUsersMasterProvider.overrideWith(_Users.new),
      ],
      child: ShadApp(
        home: ShadToaster(
          child: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                // Keep the session alive, as the app's router does.
                ref.watch(authStateProvider);
                return TextButton(
                  onPressed: () => save(ref, context),
                  child: const Text('save'),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(auth.builds, 1);
  await tester.tap(find.text('save'));
  await tester.pumpAndSettle();
  return auth;
}

UserPrivate? _signedIn(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.text('save')),
).read(authStateProvider).valueOrNull;

void main() {
  group('Issue 231: a profile save does not restore the session', () {
    testWidgets('Issue 231: an admin saving a section of another member leaves '
        'the session alone', (tester) async {
      UserPrivate? before;
      final auth = await _runSave(tester, (ref, context) {
        before = ref.read(authStateProvider).valueOrNull;
        return applyUserUpdate(
          ref,
          context,
          'robin',
          (notifier) => notifier.updateUser('robin', bio: () => 'new bio'),
          successMessage: 'Saved.',
        );
      });

      expect(auth.builds, 1, reason: 'no session restore');
      expect(identical(_signedIn(tester), before), isTrue);
    });

    testWidgets('Issue 231: saving your own section replaces the signed-in '
        'user without a restore', (tester) async {
      final auth = await _runSave(
        tester,
        (ref, context) => applyUserUpdate(
          ref,
          context,
          'admin1',
          (notifier) => notifier.updateUser('admin1', bio: () => 'my bio'),
          successMessage: 'Saved.',
        ),
      );

      expect(auth.builds, 1, reason: 'no session restore');
      expect(_signedIn(tester)?.bio, 'my bio');
    });

    testWidgets(
      'Issue 231: an admin saving the bio of another member leaves the '
      'session alone',
      (tester) async {
        final auth = await _runSave(
          tester,
          (ref, context) =>
              adminSaveUserField(ref, context, 'robin', bio: () => 'new bio'),
        );

        expect(auth.builds, 1, reason: 'no session restore');
        expect(_signedIn(tester)?.bio, isNull);
      },
    );

    testWidgets('Issue 231: saving your own bio replaces the signed-in user '
        'without a restore', (tester) async {
      final auth = await _runSave(
        tester,
        (ref, context) =>
            adminSaveUserField(ref, context, 'admin1', bio: () => 'my bio'),
      );

      expect(auth.builds, 1, reason: 'no session restore');
      expect(_signedIn(tester)?.bio, 'my bio');
    });
  });
}
