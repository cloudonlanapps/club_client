import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/identity_documents_privacy_policy_strings.dart';
import '../models/identity_documents_submit_sizes.dart';

/// "How we handle your Aadhaar" dialog, opened from the privacy link of the
/// consent line on the submit-documents step.
class IdentityDocumentsPrivacyPolicyDialog extends StatelessWidget {
  const IdentityDocumentsPrivacyPolicyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadDialog(
      title: const Text(IdentityDocumentsPrivacyPolicyStrings.title),
      actions: [
        ShadButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(IdentityDocumentsPrivacyPolicyStrings.close),
        ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: IdentityDocumentsSubmitSizes.policyMaxWidth,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: IdentityDocumentsSubmitSizes.policyParagraphGap,
            children: [
              for (final paragraph
                  in IdentityDocumentsPrivacyPolicyStrings.paragraphs)
                Text(paragraph, style: theme.textTheme.p),
            ],
          ),
        ),
      ),
    );
  }
}
