import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';

/// A `pending` member's own profile at `/onboarding/profile`
/// (club_client#340): the profile's cards, each with its edit button, and
/// then, when the host gives it, the Applications section at the end.
///
/// Both come from the host ([profile], [applications]): this package does
/// not hold the profile's cards or the applications. Each card edits in
/// place and saves its own fields.
class OnboardingProfileView extends StatelessWidget {
  const OnboardingProfileView({
    required this.currentUser,
    required this.profile,
    this.applications,
    super.key,
  });

  /// Key of the page's column, for tests.
  static const Key bodyKey = ValueKey('onboarding.profile.body');

  /// Widest the page's column grows on a wide screen.
  static const double maxWidth = 960;

  /// Gap between the profile's cards and the Applications section.
  static const double gap = 20;

  /// The signed-in member, `pending`.
  final UserPrivate currentUser;

  /// The profile's cards for [currentUser].
  final Widget profile;

  /// The Applications section for [currentUser]; null shows none.
  final Widget? applications;

  @override
  Widget build(BuildContext context) {
    assert(
      currentUser.status == UserStatus.pending,
      'OnboardingProfileView called with unexpected status '
      '${currentUser.status}. OnboardingProfileScreen gate '
      '(OnboardingGate.pending) failed.',
    );
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              key: bodyKey,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: gap,
              children: [
                profile,
                ?applications,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
