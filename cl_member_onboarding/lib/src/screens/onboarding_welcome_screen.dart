import 'dart:async';

import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorView;

import '../models/onboarding_gate.dart';
import '../models/onboarding_write_messages.dart';
import '../views/onboarding_welcome_view.dart';

/// Screen that gates `/onboarding/welcome` and mounts
/// [OnboardingWelcomeView].
///
/// Watches [authStateProvider], evaluates the welcome gate
/// (`registered` or `pending`), and renders [AccessDeniedView] when the
/// gate fails. The view itself is presentational and never watches auth.
///
/// A `registered` user's next step depends on the server's
/// `identityVerification` (#84), so the screen waits for
/// [capabilitiesProvider] and offers a retry if it cannot be read rather
/// than guessing.
class OnboardingWelcomeScreen extends ConsumerWidget {
  const OnboardingWelcomeScreen({
    required this.onContinue,
    required this.onHome,
    this.onAddProfileDetails,
    this.applications,
    super.key,
  });

  final VoidCallback onContinue;
  final VoidCallback onHome;

  /// Opens the optional extended-profile step from the waiting page
  /// (club_client#320). Offered only while the server reports the extended
  /// profile on; null offers it never.
  final VoidCallback? onAddProfileDetails;

  /// Builds the waiting page's list of the published applications for the
  /// signed-in member (club_client#321). Shown only while the server offers
  /// applications; null shows it never. The host builds it: this package
  /// does not hold it.
  final Widget Function(UserPrivate currentUser)? applications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!onboardingGateAllows(OnboardingGate.registeredOrPending, user)) {
      return AccessDeniedView(
        onHome: onHome,
        message: onboardingStepClosedMessage,
      );
    }
    final caps = ref.watch(capabilitiesProvider);
    if (user.status == UserStatus.registered && !caps.hasValue) {
      if (caps.hasError) {
        return ErrorView(
          title: 'Could not load this page',
          subtitle: 'Check your connection and try again.',
          onRetry: () => ref.invalidate(capabilitiesProvider),
          onHome: onHome,
        );
      }
      return const Center(child: CircularProgressIndicator());
    }
    return OnboardingWelcomeView(
      currentUser: user,
      onContinue: onContinue,
      onSubmitForReview: () => unawaited(_submitForReview(context, ref)),
      identityVerification: caps.valueOrNull?.identityVerification ?? true,
      onAddProfileDetails: caps.valueOrNull?.extendedProfile == true
          ? onAddProfileDetails
          : null,
      // The list is the waiting page's, so it is built for it alone.
      applications:
          user.status == UserStatus.pending &&
              caps.valueOrNull?.applications == true
          ? applications?.call(user)
          : null,
    );
  }

  /// With identity verification off there is no document step: the
  /// application goes to review from the welcome page (#84).
  Future<void> _submitForReview(BuildContext context, WidgetRef ref) async {
    try {
      final updated = await ref
          .read(clUsersMasterProvider.notifier)
          .submitForReviewForSelf();
      ref.read(authStateProvider.notifier).setUser(updated);
    } on Object catch (error) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            writeFailureMessage(error, fallback: submissionFailedMessage),
          ),
        ),
      );
    }
  }
}
