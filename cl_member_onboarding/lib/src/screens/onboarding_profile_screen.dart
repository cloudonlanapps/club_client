import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/onboarding_gate.dart';
import '../views/onboarding_profile_view.dart';

/// Screen that gates `/onboarding/profile` and mounts
/// [OnboardingProfileView] (club_client#340).
///
/// Open to a `pending` member whatever the server's capabilities say;
/// anyone else gets [AccessDeniedView]. The profile's cards and the
/// Applications section come from the host ([profile], [applications]),
/// since this package holds neither. The Applications section is shown
/// only while the server offers applications.
class OnboardingProfileScreen extends ConsumerWidget {
  const OnboardingProfileScreen({
    required this.profile,
    required this.onHome,
    this.applications,
    super.key,
  });

  /// Builds the profile's cards for the signed-in member.
  final Widget Function(UserPrivate currentUser) profile;

  /// Builds the Applications section for the signed-in member; null shows
  /// it never.
  final Widget Function(UserPrivate currentUser)? applications;

  /// Leaves a refused page for home.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!onboardingGateAllows(OnboardingGate.pending, user)) {
      return AccessDeniedView(
        onHome: onHome,
        message: onboardingStepClosedMessage,
      );
    }
    final applicationsOn = ref.watch(applicationsProvider) == true;
    return OnboardingProfileView(
      currentUser: user,
      profile: profile(user),
      applications: applicationsOn ? applications?.call(user) : null,
    );
  }
}
