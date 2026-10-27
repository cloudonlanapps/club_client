import 'package:cl_member_onboarding/cl_member_onboarding.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

UserPrivate _user(UserStatus status) => UserPrivate(
  username: 'u1',
  displayName: 'U One',
  status: status,
  isSuperAdmin: false,
  roles: const UserRoles(),
  createdAtUtc: DateTime.utc(2024),
);

void main() {
  group('Issue 340: the profile page in onboarding', () {
    test('Issue 340: a pending member may open their profile page whatever '
        'the server reports', () {
      for (final verification in [true, false, null]) {
        expect(
          allowedOnboardingPaths(
            _user(UserStatus.pending),
            identityVerification: verification,
          ),
          contains(onboardingProfilePath),
          reason: 'identity verification $verification',
        );
      }
    });

    test('Issue 340: a registered member may not', () {
      for (final verification in [true, false, null]) {
        expect(
          allowedOnboardingPaths(
            _user(UserStatus.registered),
            identityVerification: verification,
          ),
          isNot(contains(onboardingProfilePath)),
        );
      }
    });

    test('Issue 340: the extended-profile step is gone', () {
      for (final status in [UserStatus.registered, UserStatus.pending]) {
        expect(
          allowedOnboardingPaths(_user(status), identityVerification: true),
          isNot(contains('/onboarding/extended-profile')),
        );
      }
    });

    test('Issue 340: submitting the document lands on the waiting page', () {
      final pending = _user(UserStatus.pending);
      expect(
        onboardingFallbackPath(pending, onboardingSubmitDocumentsPath),
        onboardingWelcomePath,
      );
      expect(
        onboardingFallbackPath(pending, '/onboarding/extended-profile'),
        onboardingWelcomePath,
      );
    });
  });
}
