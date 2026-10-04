import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/public/detail_labels/event_detail_labels.dart';
import '../../../models/public/public_event_view.dart';
import 'public_event_coaches_card.dart';
import 'public_event_highlights_card.dart';

class PublicEventHighlightsAndCoaches extends StatelessWidget {
  const PublicEventHighlightsAndCoaches({
    required this.event,
    required this.labels,
    super.key,
    this.showHighlights = true,
  });
  final PublicEventView event;
  final EventDetailLabels labels;
  final bool showHighlights;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;
    final themeColor = theme.colorScheme.primary;

    // If no highlights to show, just show coach/training card
    if (!showHighlights) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: isMobile ? 40 : 60,
          horizontal: isMobile ? 24 : 48,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: PublicEventCoachesCard(
              event: event,
              labels: labels.coach,
              themeColor: themeColor,
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
        horizontal: isMobile ? 24 : 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: isMobile
              ? Column(
                  children: [
                    PublicEventHighlightsCard(
                      event: event,
                      labels: labels.highlights,
                      themeColor: themeColor,
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 40),
                    PublicEventCoachesCard(
                      event: event,
                      labels: labels.coach,
                      themeColor: themeColor,
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: PublicEventHighlightsCard(
                        event: event,
                        labels: labels.highlights,
                        themeColor: themeColor,
                        isMobile: isMobile,
                      ),
                    ),
                    const SizedBox(width: 48),
                    Expanded(
                      flex: 4,
                      child: PublicEventCoachesCard(
                        event: event,
                        labels: labels.coach,
                        themeColor: themeColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
