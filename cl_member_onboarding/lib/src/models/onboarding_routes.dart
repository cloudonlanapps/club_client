import 'package:club_sdk_2/club_sdk_2.dart';

/// The onboarding welcome page, open to every `registered` or `pending` user.
const onboardingWelcomePath = '/onboarding/welcome';

/// The identity-document step.
const onboardingSubmitDocumentsPath = '/onboarding/submit-documents';

/// The optional extended-profile step, after the document is submitted
/// (club_client#320).
const onboardingExtendedProfilePath = '/onboarding/extended-profile';

/// The onboarding paths a signed-in [user] may open, or null when onboarding
/// does not apply to them (an active member, say).
///
/// A `registered` user may open the document step only when they have no
/// admin review note (the reapply form comes first) and the server does not
/// report identity verification off (#84). While [identityVerification] is
/// still unknown (null) the step stays open, as before; the router re-checks
/// once the capability arrives.
///
/// A `pending` user may also open the optional extended-profile step while
/// the server reports [extendedProfile] on (club_client#320); not while it
/// is off or unknown.
Set<String>? allowedOnboardingPaths(
  UserPrivate user, {
  required bool? identityVerification,
  bool? extendedProfile,
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
      return {
        onboardingWelcomePath,
        if (extendedProfile == true) onboardingExtendedProfilePath,
      };
    case UserStatus.active:
    case UserStatus.blocked:
    case UserStatus.left:
      return null;
  }
}

/// Where an onboarding [user] goes from [path] when they may not open it
/// ([allowedOnboardingPaths]): the welcome page, except that a member who
/// has just submitted their document, and so is `pending` on the document
/// step, goes on to the optional extended-profile step while
/// [extendedProfile] is on (club_client#320). Its Continue leads to the
/// welcome page, which then shows the waiting card.
String onboardingFallbackPath(
  UserPrivate user,
  String path, {
  required bool? extendedProfile,
}) {
  final justSubmitted =
      user.status == UserStatus.pending &&
      path == onboardingSubmitDocumentsPath;
  return justSubmitted && extendedProfile == true
      ? onboardingExtendedProfilePath
      : onboardingWelcomePath;
}
