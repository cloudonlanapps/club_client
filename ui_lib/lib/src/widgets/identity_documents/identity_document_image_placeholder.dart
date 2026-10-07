import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/identity_document_sizes.dart';
import 'identity_documents_strings.dart';

/// Stands in for an uploaded image whose preview cannot load.
class IdentityDocumentImagePlaceholder extends StatelessWidget {
  const IdentityDocumentImagePlaceholder({this.filename, super.key});

  /// The file's name, when known.
  final String? filename;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Container(
      color: theme.colorScheme.muted,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: IdentityDocumentSizes.textPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: IdentityDocumentSizes.iconTextGap,
        children: [
          const Icon(
            Icons.image_outlined,
            size: IdentityDocumentSizes.placeholderIcon,
          ),
          Text(
            filename ?? IdentityDocumentsStrings.unnamedImage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.small.copyWith(
              fontSize: IdentityDocumentSizes.fileNameFontSize,
            ),
          ),
        ],
      ),
    );
  }
}
