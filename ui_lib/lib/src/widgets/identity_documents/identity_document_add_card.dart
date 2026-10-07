import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/identity_document_sizes.dart';
import 'identity_document_card_frame.dart';

/// The card that picks a file to upload.
class IdentityDocumentAddCard extends StatelessWidget {
  const IdentityDocumentAddCard({required this.onTap, this.label, super.key});

  /// Called on a tap.
  final VoidCallback onTap;

  /// Optional label rendered under the plus icon. When the card is the
  /// secondary "back side" affordance it's labelled so the user
  /// understands the second slot is not a second required document.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final text = label;
    return IdentityDocumentCardFrame(
      onTap: onTap,
      child: ColoredBox(
        color: theme.colorScheme.muted.withValues(
          alpha: IdentityDocumentSizes.addCardFill,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: IdentityDocumentSizes.iconTextGap,
            children: [
              Icon(
                Icons.add,
                size: text == null
                    ? IdentityDocumentSizes.addIcon
                    : IdentityDocumentSizes.addIconWithLabel,
                color: theme.colorScheme.mutedForeground,
              ),
              if (text != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: IdentityDocumentSizes.textPadding,
                  ),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.small.copyWith(
                      color: theme.colorScheme.mutedForeground,
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
