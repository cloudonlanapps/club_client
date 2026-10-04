import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'history_content.dart';
import 'values_content.dart';

/// Club content section with history and values.
class ClubContentSection extends StatelessWidget {
  const ClubContentSection({required this.clubInfo, super.key});
  final ClubInfo clubInfo;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    return Column(
      children: [
        // History section
        HistoryContent(data: clubInfo.history, isMobile: isMobile),
        SizedBox(height: isMobile ? 40 : 60),
        // Values section with muted background
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 40 : 60,
            horizontal: isMobile ? 24 : 48,
          ),
          color: theme.colorScheme.muted.withValues(alpha: 0.3),
          child: ValuesContent(values: clubInfo.values),
        ),
      ],
    );
  }
}
