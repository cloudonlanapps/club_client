import 'package:club_sdk_2/club_sdk_2.dart';

/// What an onboarding screen tells a member its gate refuses, under
/// `AccessDeniedView`'s own title (club_client#328).
const onboardingStepClosedMessage = "This step isn't open to you right now.";

/// Which user states are allowed to view a given onboarding screen.
///
/// Package-private — only the screens inside `cl_member_onboarding`
/// consume this. The host router does not see the enum.
enum OnboardingGate {
  /// `status ∈ {registered, pending}` — used by `/onboarding/welcome`.
  registeredOrPending,

  /// `status == registered && (adminReviewNote ?? '').isEmpty` —
  /// used by `/onboarding/submit-documents`.
  registeredNoNote,

  /// `status == pending` — used by `/onboarding/extended-profile`.
  pending,
}

bool onboardingGateAllows(OnboardingGate gate, UserPrivate user) {
  switch (gate) {
    case OnboardingGate.registeredOrPending:
      return user.status == UserStatus.registered ||
          user.status == UserStatus.pending;
    case OnboardingGate.registeredNoNote:
      return user.status == UserStatus.registered &&
          (user.adminReviewNote ?? '').isEmpty;
    case OnboardingGate.pending:
      return user.status == UserStatus.pending;
  }
}
