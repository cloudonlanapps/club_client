import 'dart:async';

import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorTone, ErrorView;

import '../models/onboarding_gate.dart';
import '../models/onboarding_write_messages.dart';
import '../views/onboarding_welcome_view.dart';

/// Screen that gates `/onboarding/welcome` and mounts
/// [OnboardingWelcomeView].
///
/// Watches [authStateProvider], evaluates the welcome gate
/// (`registered` or `pending`), and renders [ErrorView] when the gate
/// fails. The view itself is presentational and never watches auth.
///
/// A `registered` user's next step depends on the server's
/// `identityVerification` (#84), so the screen waits for
/// [capabilitiesProvider] and offers a retry if it cannot be read rather
/// than guessing.
class OnboardingWelcomeScreen extends ConsumerWidget {
  const OnboardingWelcomeScreen({
    required this.onContinue,
    required this.onHome,
    super.key,
  });

  final VoidCallback onContinue;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!onboardingGateAllows(OnboardingGate.registeredOrPending, user)) {
      return ErrorView(
        tone: ErrorTone.neutral,
        icon: LucideIcons.shieldAlert,
        title: 'Not available',
        subtitle: "This page isn't available right now.",
        onHome: onHome,
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
