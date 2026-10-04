import 'package:cl_member_onboarding/cl_member_onboarding.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

UserPrivate _user(UserStatus status, {String? note}) => UserPrivate(
  username: 'u1',
  displayName: 'U One',
  status: status,
  isSuperAdmin: false,
  roles: const UserRoles(),
  createdAtUtc: DateTime.utc(2024),
  adminReviewNote: note,
);

void main() {
  group('Issue 84: allowedOnboardingPaths', () {
    test('verification on: a registered user may reach the document step', () {
      expect(
        allowedOnboardingPaths(
          _user(UserStatus.registered),
          identityVerification: true,
        ),
        {onboardingWelcomePath, onboardingSubmitDocumentsPath},
      );
    });

    test('verification off: there is no document step', () {
      expect(
        allowedOnboardingPaths(
          _user(UserStatus.registered),
          identityVerification: false,
        ),
        {onboardingWelcomePath},
      );
    });

    test('unknown: the document step stays open until the server answers', () {
      expect(
        allowedOnboardingPaths(
          _user(UserStatus.registered),
          identityVerification: null,
        ),
        {onboardingWelcomePath, onboardingSubmitDocumentsPath},
      );
    });

    test('a review note sends the user to the reapply form first', () {
      expect(
        allowedOnboardingPaths(
          _user(UserStatus.registered, note: 'fix your phone'),
          identityVerification: true,
        ),
        {onboardingWelcomePath},
      );
    });

    test('a pending user sees only the welcome page', () {
      for (final on in [true, false, null]) {
        expect(
          allowedOnboardingPaths(
            _user(UserStatus.pending),
            identityVerification: on,
          ),
          {onboardingWelcomePath},
        );
      }
    });

    test('onboarding does not apply to an active member', () {
      expect(
        allowedOnboardingPaths(
          _user(UserStatus.active),
          identityVerification: true,
        ),
        isNull,
      );
    });
  });
}
