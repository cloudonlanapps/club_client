import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/page_section_header_data.dart';
import 'section_header.dart';

/// Past content section with header and muted background.
class PastSection extends StatelessWidget {
  const PastSection({
    required this.sectionData,
    required this.isMobile,
    required this.child,
    super.key,
  });
  final PageSectionHeaderData sectionData;
  final bool isMobile;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
        horizontal: isMobile ? 16 : 48,
      ),
      color: theme.colorScheme.muted.withValues(alpha: 0.3),
      child: Column(
        children: [
          SectionHeader(sectionData: sectionData, isMobile: isMobile),
          child,
        ],
      ),
    );
  }
}
