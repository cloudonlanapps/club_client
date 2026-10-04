import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ClubTextTheme, ThemedMarkdown;

import '../page_content/page_common.dart';

/// Section header with badge, title, and description.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.sectionData,
    required this.isMobile,
    super.key,
  });
  final PageSectionHeaderData sectionData;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Column(
      children: [
        if (sectionData.badge != null)
          ShadBadge.outline(
            child: Text(sectionData.badge!, style: theme.textTheme.badgeText),
          ),
        const SizedBox(height: 16),
        Text(
          sectionData.title,
          style: theme.textTheme.sectionTitle(isMobile: isMobile),
          textAlign: TextAlign.center,
        ),
        if (sectionData.description != null) ...[
          const SizedBox(height: 8),
          ThemedMarkdown(
            data: sectionData.description!,
            selectable: false,
            textStyle: theme.textTheme.sectionDescription(isMobile: isMobile),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}
