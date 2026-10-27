import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show isMobileWidth;

import '../models/onboarding_profile_strings.dart';

/// The waiting page: the application is submitted and under review.
class SubmittedConfirmation extends StatelessWidget {
  const SubmittedConfirmation({
    required this.onBack,
    this.onUpdateProfile,
    this.applications,
    super.key,
  });

  /// Signs out.
  final VoidCallback onBack;

  /// Opens the member's profile page (club_client#340); null shows no
  /// button for it.
  final VoidCallback? onUpdateProfile;

  /// The published applications to download, with what to do with the
  /// form (club_client#321); null shows none.
  final Widget? applications;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isMobile = isMobileWidth(context);
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 420,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.hourglass_top_outlined,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Thanks for signing up!',
                  style: theme.textTheme.h3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "We're reviewing your application now - you'll hear "
                  'from us shortly.',
                  style: theme.textTheme.p,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (applications case final applications?) ...[
                  applications,
                  const SizedBox(height: 24),
                ],
                if (onUpdateProfile case final onUpdateProfile?) ...[
                  ShadButton.outline(
                    onPressed: onUpdateProfile,
                    child: const Text(OnboardingProfileStrings.updateProfile),
                  ),
                  const SizedBox(height: 12),
                ],
                ShadButton(
                  onPressed: onBack,
                  child: const Text('Back to sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
