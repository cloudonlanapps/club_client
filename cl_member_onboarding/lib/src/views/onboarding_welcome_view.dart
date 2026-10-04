import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/intro_card.dart';
import '../widgets/reapply_variant.dart';
import '../widgets/submitted_confirmation.dart';

/// Single info surface mounted at `/onboarding/welcome` for every
/// onboarding state.
///
/// Variant selection is driven entirely by the (non-null) [currentUser]:
///
/// - `status == registered`, no `adminReviewNote` → intro card with a
///   "Continue" button that calls [onContinue]. The host routes that to
///   `/onboarding/submit-documents`.
/// - `status == registered`, non-empty `adminReviewNote` → SignupForm
///   in reapply mode (username pinned, banner shows the admin note).
///   On submit calls
///   `clUsersMasterProvider.notifier.reapplyForSelf(...)`, propagates
///   the response into `authStateProvider.setUser`, then calls
///   [onContinue].
/// - `status == pending` → "application submitted, awaiting approval"
///   confirmation card with a "Back to sign in" button that logs out.
class OnboardingWelcomeView extends ConsumerWidget {
  const OnboardingWelcomeView({
    required this.currentUser,
    required this.onContinue,
    required this.onSubmitForReview,
    required this.identityVerification,
    super.key,
  });

  final UserPrivate currentUser;

  /// Where the host routes after the user finishes the welcome step
  /// in the two `registered` variants when [identityVerification] is on.
  /// Bound by the router to `context.go('/onboarding/submit-documents')`.
  final VoidCallback onContinue;

  /// What finishes the welcome step when [identityVerification] is off:
  /// there is no document to upload, so the application goes straight to
  /// review (#84).
  final VoidCallback onSubmitForReview;

  /// Whether the server asks new members for an identity document
  /// (`Capabilities.identityVerification`).
  final bool identityVerification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(
      currentUser.status == UserStatus.registered ||
          currentUser.status == UserStatus.pending,
      'OnboardingWelcomeView called with unexpected status '
      '${currentUser.status}. OnboardingWelcomeScreen gate '
      '(OnboardingGate.registeredOrPending) failed.',
    );
    if (currentUser.status == UserStatus.pending) {
      return SubmittedConfirmation(
        onBack: () => ref.read(authStateProvider.notifier).logout(),
      );
    }
    final next = identityVerification ? onContinue : onSubmitForReview;
    final note = currentUser.adminReviewNote;
    if (note != null && note.isNotEmpty) {
      return ReapplyVariant(
        currentUser: currentUser,
        onContinue: next,
      );
    }
    return IntroCard(
      documentsRequired: identityVerification,
      onContinue: next,
    );
  }
}
