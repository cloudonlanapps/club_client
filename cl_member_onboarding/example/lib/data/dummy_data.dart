import 'package:club_sdk_2/club_sdk_2.dart';

/// Three onboarding-state variants exercised by the demo.
enum OnboardingScenario {
  registeredFresh('Registered (no admin note)'),
  registeredReapply('Registered (admin note → reapply)'),
  pending('Pending (awaiting approval)');

  const OnboardingScenario(this.label);
  final String label;
}

class DummyData {
  DummyData._();

  static UserPrivate userFor(OnboardingScenario scenario) {
    switch (scenario) {
      case OnboardingScenario.registeredFresh:
        return _registered();
      case OnboardingScenario.registeredReapply:
        return _registered(
          adminReviewNote:
              'Please correct your phone number — the one on file is not '
              'reachable.',
        );
      case OnboardingScenario.pending:
        return _pending();
    }
  }

  static UserPrivate _registered({String? adminReviewNote}) {
    return UserPrivate(
      username: 'rohan.demo',
      displayName: 'Rohan Demo',
      firstName: 'Rohan',
      lastName: 'Demo',
      status: UserStatus.registered,
      isSuperAdmin: false,
      roles: const UserRoles(),
      createdAtUtc: DateTime.utc(2026, 4),
      adminReviewNote: adminReviewNote,
      email: 'rohan.demo@example.com',
      phone: '+91-9000000001',
      dateOfBirthUtc: DateTime.utc(2002, 6, 12),
      gender: Gender.male,
    );
  }

  static UserPrivate _pending() {
    return UserPrivate(
      username: 'rohan.demo',
      displayName: 'Rohan Demo',
      firstName: 'Rohan',
      lastName: 'Demo',
      status: UserStatus.pending,
      isSuperAdmin: false,
      roles: const UserRoles(),
      createdAtUtc: DateTime.utc(2026, 4),
      email: 'rohan.demo@example.com',
      phone: '+91-9000000001',
      dateOfBirthUtc: DateTime.utc(2002, 6, 12),
      gender: Gender.male,
    );
  }
}
