import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/identity_document_sizes.dart';

/// The small round button that removes an uploaded identity document.
class IdentityDocumentRemoveButton extends StatelessWidget {
  const IdentityDocumentRemoveButton({required this.onPressed, super.key});

  /// Called on a tap.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.background.withValues(
              alpha: IdentityDocumentSizes.removeFill,
            ),
          ),
          padding: const EdgeInsets.all(IdentityDocumentSizes.removePadding),
          child: Icon(
            Icons.close,
            size: IdentityDocumentSizes.removeIcon,
            color: theme.colorScheme.foreground,
          ),
        ),
      ),
    );
  }
}
