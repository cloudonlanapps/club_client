import 'package:club_sdk_2/club_sdk_2.dart';

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ThemedMarkdown;

/// History content with badge, title, and paragraphs.
class HistoryContent extends StatelessWidget {
  const HistoryContent({required this.data, required this.isMobile, super.key});
  final ClubHistoryData data;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1000),
      child: ThemedMarkdown(
        data: data.text,
        selectable: false,
        textStyle: theme.textTheme.muted.copyWith(fontSize: 16, height: 1.8),
        textAlign: TextAlign.justify,
      ),
    );
  }
}
