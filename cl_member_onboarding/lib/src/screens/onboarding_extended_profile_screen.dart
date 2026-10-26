import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorTone, ErrorView;

import '../models/onboarding_gate.dart';
import '../views/onboarding_extended_profile_view.dart';

/// Screen that gates `/onboarding/extended-profile` and mounts
/// [OnboardingExtendedProfileView] (club_client#320).
///
/// Open to a `pending` member while the server reports the extended profile
/// on; anyone else, or a server with it off, gets [ErrorView]. It waits for
/// [capabilitiesProvider] rather than guessing.
///
/// The sections come from the host ([sections]), which builds the profile's
/// own section editors for the member: this package does not hold them.
class OnboardingExtendedProfileScreen extends ConsumerWidget {
  const OnboardingExtendedProfileScreen({
    required this.sections,
    required this.onContinue,
    required this.onHome,
    super.key,
  });

  /// Builds the extended profile's sections for the signed-in member.
  final Widget Function(UserPrivate currentUser) sections;

  /// Leaves the step for the waiting page.
  final VoidCallback onContinue;

  /// Returns to the app's home from the not-available page.
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final caps = ref.watch(capabilitiesProvider);
    if (user == null || (!caps.hasValue && !caps.hasError)) {
      return const Center(child: CircularProgressIndicator());
    }
    final allowed =
        onboardingGateAllows(OnboardingGate.pending, user) &&
        caps.valueOrNull?.extendedProfile == true;
    if (!allowed) {
      return ErrorView(
        tone: ErrorTone.neutral,
        icon: LucideIcons.shieldAlert,
        title: 'Not available',
        subtitle: "This page isn't available right now.",
        onHome: onHome,
      );
    }
    return OnboardingExtendedProfileView(
      currentUser: user,
      sections: sections(user),
      onContinue: onContinue,
    );
  }
}
