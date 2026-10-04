import 'package:cl_remote_store/cl_remote_store.dart'
    show ClUsersMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';

/// Stub of `clUsersMasterProvider` that intercepts the two self-actions
/// the onboarding flow uses, returning a synthetic `UserPrivate` so the
/// real SDK is never reached.
class DummyUsersMasterNotifier extends ClUsersMasterNotifier {
  @override
  Future<Map<String, UserInfo>> build() async => const {};

  @override
  Future<UserPrivate> submitForReviewForSelf() async {
    return _selfWith(status: UserStatus.pending);
  }

  @override
  Future<UserPrivate> reapplyForSelf({
    String? firstName,
    String? middleName,
    String? lastName,
    DateTime? dateOfBirthUtc,
    Gender? gender,
    String? phone,
    String? email,
  }) async {
    // Mirror the server: status stays `registered`, adminReviewNote clears.
    return _selfWith(
      status: UserStatus.registered,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      dateOfBirthUtc: dateOfBirthUtc,
      gender: gender,
      phone: phone,
      email: email,
    );
  }

  UserPrivate _selfWith({
    required UserStatus status,
    String? firstName,
    String? middleName,
    String? lastName,
    DateTime? dateOfBirthUtc,
    Gender? gender,
    String? phone,
    String? email,
  }) {
    return UserPrivate(
      username: 'rohan.demo',
      displayName: 'Rohan Demo',
      firstName: firstName ?? 'Rohan',
      middleName: middleName,
      lastName: lastName ?? 'Demo',
      status: status,
      isSuperAdmin: false,
      roles: const UserRoles(),
      createdAtUtc: DateTime.utc(2026, 4),
      email: email ?? 'rohan.demo@example.com',
      phone: phone ?? '+91-9000000001',
      dateOfBirthUtc: dateOfBirthUtc ?? DateTime.utc(2002, 6, 12),
      gender: gender ?? Gender.male,
    );
  }
}
