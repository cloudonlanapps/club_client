import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/identity_documents_submit_sizes.dart';
import '../models/identity_documents_submit_strings.dart';

/// The buttons of the submit-documents step: leave it for later, or submit
/// the application for review. With no document uploaded Submit is disabled
/// and the reason shows above it.
class IdentityDocumentsSubmitActions extends StatelessWidget {
  const IdentityDocumentsSubmitActions({
    required this.hasDocument,
    required this.submitting,
    required this.onSubmit,
    required this.onDoLater,
    super.key,
  });

  /// Whether at least one document is uploaded.
  final bool hasDocument;

  /// Whether the application is being sent.
  final bool submitting;

  /// Submits the application for review.
  final VoidCallback onSubmit;

  /// Leaves the step.
  final VoidCallback onDoLater;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final canSubmit = hasDocument && !submitting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      spacing: IdentityDocumentsSubmitSizes.buttonGap,
      children: [
        if (!hasDocument)
          Text(
            IdentityDocumentsSubmitStrings.needsDocument,
            style: theme.textTheme.muted,
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: IdentityDocumentsSubmitSizes.buttonGap,
          children: [
            ShadButton.ghost(
              onPressed: submitting ? null : onDoLater,
              child: Text(
                IdentityDocumentsSubmitStrings.doLater,
                style: theme.textTheme.muted,
              ),
            ),
            ShadButton(
              enabled: canSubmit,
              onPressed: canSubmit ? onSubmit : null,
              child: Text(
                submitting
                    ? IdentityDocumentsSubmitStrings.submitting
                    : IdentityDocumentsSubmitStrings.submit,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
