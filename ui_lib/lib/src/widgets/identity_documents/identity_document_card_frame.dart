import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/identity_document_sizes.dart';
import '../../constants/identity_documents.dart';

/// The bordered, card-shaped frame every identity-document card sits in.
class IdentityDocumentCardFrame extends StatelessWidget {
  const IdentityDocumentCardFrame({required this.child, this.onTap, super.key});

  /// What the card shows.
  final Widget child;

  /// Called on a tap; null leaves the card inert.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final radius = BorderRadius.circular(IdentityDocumentSizes.cardRadius);
    final content = AspectRatio(
      aspectRatio: kIdentityDocCardAspect,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.card,
          border: Border.all(color: theme.colorScheme.border),
          borderRadius: radius,
        ),
        child: ClipRRect(borderRadius: radius, child: child),
      ),
    );
    if (onTap == null) return content;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: content,
      ),
    );
  }
}
