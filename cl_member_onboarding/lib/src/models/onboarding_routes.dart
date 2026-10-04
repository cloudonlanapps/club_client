import 'package:club_sdk_2/club_sdk_2.dart';

/// The onboarding welcome page, open to every `registered` or `pending` user.
const onboardingWelcomePath = '/onboarding/welcome';

/// The identity-document step.
const onboardingSubmitDocumentsPath = '/onboarding/submit-documents';

/// The onboarding paths a signed-in [user] may open, or null when onboarding
/// does not apply to them (an active member, say).
///
/// A `registered` user may open the document step only when they have no
/// admin review note (the reapply form comes first) and the server does not
/// report identity verification off (#84). While [identityVerification] is
/// still unknown (null) the step stays open, as before; the router re-checks
/// once the capability arrives.
Set<String>? allowedOnboardingPaths(
  UserPrivate user, {
  required bool? identityVerification,
}) {
  switch (user.status) {
    case UserStatus.registered:
      final hasNote = (user.adminReviewNote ?? '').isNotEmpty;
      final documentStep = !hasNote && identityVerification != false;
      return {
        onboardingWelcomePath,
        if (documentStep) onboardingSubmitDocumentsPath,
      };
    case UserStatus.pending:
      return {onboardingWelcomePath};
    case UserStatus.active:
    case UserStatus.blocked:
    case UserStatus.left:
      return null;
  }
}
