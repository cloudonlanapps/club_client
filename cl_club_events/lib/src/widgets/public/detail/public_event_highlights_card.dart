import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ClubTextTheme;

import '../../../models/public/detail_labels/event_detail_highlights_labels.dart';
import '../../../models/public/public_event_view.dart';

class PublicEventHighlightsCard extends StatelessWidget {
  const PublicEventHighlightsCard({
    required this.event,
    required this.labels,
    required this.themeColor,
    required this.isMobile,
    super.key,
  });
  final PublicEventView event;
  final EventDetailHighlightsLabels labels;
  final Color themeColor;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final highlights = event.highlights ?? [];
    final sectionTitle = event.isActive ? labels.titleActive : labels.titlePast;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionTitle,
          style: theme.textTheme.subsectionTitle(isMobile: isMobile),
        ),
        const SizedBox(height: 24),
        ...highlights.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.check, size: 16, color: themeColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: theme.textTheme.p.copyWith(fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
