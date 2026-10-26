import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show isMobileWidth;

import '../models/onboarding_extended_profile_strings.dart';

/// Onboarding's optional extended-profile step at
/// `/onboarding/extended-profile` (club_client#320): after the identity
/// document is submitted, the member may fill in their sports details,
/// background and guardian, or leave any of them blank, before the waiting
/// page.
///
/// The sections are the host's ([sections]): each edits in place and saves
/// on its own, so [onContinue] stores nothing and only moves on.
class OnboardingExtendedProfileView extends StatelessWidget {
  const OnboardingExtendedProfileView({
    required this.currentUser,
    required this.sections,
    required this.onContinue,
    super.key,
  });

  /// Widest the step's column grows on a wide screen.
  static const double maxWidth = 640;

  /// Gap between the parts of the step.
  static const double gap = 16;

  /// The signed-in member, `pending`.
  final UserPrivate currentUser;

  /// The extended profile's sections for [currentUser].
  final Widget sections;

  /// Leaves the step for the waiting page.
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    assert(
      currentUser.status == UserStatus.pending,
      'OnboardingExtendedProfileView called with unexpected status '
      '${currentUser.status}. OnboardingExtendedProfileScreen gate '
      '(OnboardingGate.pending) failed.',
    );
    final theme = ShadTheme.of(context);
    final isMobile = isMobileWidth(context);
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : maxWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: gap,
              children: [
                Text(
                  OnboardingExtendedProfileStrings.title,
                  style: theme.textTheme.h3,
                ),
                Text(
                  OnboardingExtendedProfileStrings.intro,
                  style: theme.textTheme.muted,
                ),
                sections,
                ShadButton(
                  onPressed: onContinue,
                  child: const Text(
                    OnboardingExtendedProfileStrings.continueLabel,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
