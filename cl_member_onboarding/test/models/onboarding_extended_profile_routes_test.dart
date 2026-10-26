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
  group('Issue 320: the extended-profile step in onboarding', () {
    test('Issue 320: a pending user may open it while the extended profile '
        'is on', () {
      expect(
        allowedOnboardingPaths(
          _user(UserStatus.pending),
          identityVerification: true,
          extendedProfile: true,
        ),
        {onboardingWelcomePath, onboardingExtendedProfilePath},
      );
    });

    test('Issue 320: there is no such step while it is off or unknown', () {
      for (final flag in [false, null]) {
        expect(
          allowedOnboardingPaths(
            _user(UserStatus.pending),
            identityVerification: true,
            extendedProfile: flag,
          ),
          {onboardingWelcomePath},
        );
      }
    });

    test('Issue 320: a registered user does not reach it before the '
        'document step', () {
      expect(
        allowedOnboardingPaths(
          _user(UserStatus.registered),
          identityVerification: true,
          extendedProfile: true,
        ),
        {onboardingWelcomePath, onboardingSubmitDocumentsPath},
      );
    });

    test('Issue 320: submitting the document leads to the step, then the '
        'waiting page', () {
      final pending = _user(UserStatus.pending);
      expect(
        onboardingFallbackPath(
          pending,
          onboardingSubmitDocumentsPath,
          extendedProfile: true,
        ),
        onboardingExtendedProfilePath,
      );
      expect(
        onboardingFallbackPath(
          pending,
          onboardingSubmitDocumentsPath,
          extendedProfile: false,
        ),
        onboardingWelcomePath,
      );
      expect(
        onboardingFallbackPath(pending, '/memberzone', extendedProfile: true),
        onboardingWelcomePath,
      );
    });
  });
}
