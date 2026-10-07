import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/identity_document_sizes.dart';
import 'identity_document_card_frame.dart';

/// The card of a file on its way to the server.
class IdentityDocumentPendingCard extends StatelessWidget {
  const IdentityDocumentPendingCard({required this.filename, super.key});

  /// The picked file's name.
  final String filename;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return IdentityDocumentCardFrame(
      child: ColoredBox(
        color: theme.colorScheme.muted.withValues(
          alpha: IdentityDocumentSizes.pendingCardFill,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: IdentityDocumentSizes.spinnerGap,
            children: [
              const SizedBox.square(
                dimension: IdentityDocumentSizes.spinner,
                child: CircularProgressIndicator(
                  strokeWidth: IdentityDocumentSizes.spinnerStroke,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: IdentityDocumentSizes.textPadding,
                ),
                child: Text(
                  filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.muted.copyWith(
                    fontSize: IdentityDocumentSizes.fileNameFontSize,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
