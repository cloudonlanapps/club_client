import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/onboarding_gate.dart';
import '../views/onboarding_submit_documents_view.dart';

/// Screen that gates `/onboarding/submit-documents` and mounts
/// [OnboardingSubmitDocumentsView].
///
/// Watches [authStateProvider], evaluates the submit-documents gate
/// (`registered` with no admin note), and renders [AccessDeniedView]
/// when the gate fails. Forwards [onHome] so the view's error-retry can return
/// to the dashboard.
class OnboardingSubmitDocumentsScreen extends ConsumerWidget {
  const OnboardingSubmitDocumentsScreen({
    required this.onHome,
    super.key,
  });

  final VoidCallback onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!onboardingGateAllows(OnboardingGate.registeredNoNote, user)) {
      return AccessDeniedView(
        onHome: onHome,
        message: onboardingStepClosedMessage,
      );
    }
    return OnboardingSubmitDocumentsView(
      currentUser: user,
      onHome: onHome,
    );
  }
}
