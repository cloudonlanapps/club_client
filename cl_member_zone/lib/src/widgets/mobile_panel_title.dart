import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/panel_descriptor.dart';

/// Trigger row of a mobile-accordion panel: icon + title (chevron is added
/// by [ShadAccordionItem] itself).
class MobilePanelTitle extends StatelessWidget {
  const MobilePanelTitle({required this.descriptor, super.key});

  final PanelDescriptor descriptor;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Row(
      children: [
        Icon(
          descriptor.icon,
          size: 16,
          color: theme.colorScheme.mutedForeground,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            descriptor.title,
            style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
