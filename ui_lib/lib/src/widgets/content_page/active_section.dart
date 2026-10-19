import 'package:flutter/material.dart';

import '../../models/page_section_header_data.dart';
import 'section_header.dart';

/// Active content section with header.
class ActiveSection extends StatelessWidget {
  const ActiveSection({
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
        horizontal: isMobile ? 16 : 48,
      ),
      child: Column(
        children: [
          SectionHeader(sectionData: sectionData, isMobile: isMobile),
          child,
        ],
      ),
    );
  }
}
