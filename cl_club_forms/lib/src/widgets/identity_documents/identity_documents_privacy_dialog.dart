import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// "How we handle your Aadhaar" dialog — opened from the privacy link beneath
/// the agreement checkbox.
class IdentityDocumentsPrivacyPolicyDialog extends StatelessWidget {
  const IdentityDocumentsPrivacyPolicyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadDialog(
      title: const Text('How we handle your Aadhaar'),
      actions: [
        ShadButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'We only use your Aadhaar to confirm your name and date of '
                'birth. Nothing else.',
                style: theme.textTheme.p,
              ),
              const SizedBox(height: 12),
              Text(
                'We will never use it for marketing, ads, profiling, or '
                'any unrelated purpose.',
                style: theme.textTheme.p,
              ),
              const SizedBox(height: 12),
              Text(
                'Only authorised reviewers can see your files. They are '
                'securely transmitted and stored.',
                style: theme.textTheme.p,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
