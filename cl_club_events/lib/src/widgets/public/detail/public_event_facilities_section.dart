import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ClubTextTheme;

import '../../../models/public/detail_labels/event_detail_facilities_labels.dart';
import '../../../models/public/public_event_view.dart';
import 'public_event_facility_card.dart';

class PublicEventFacilitiesSection extends StatelessWidget {
  const PublicEventFacilitiesSection({
    required this.event,
    required this.labels,
    super.key,
  });
  final PublicEventView event;
  final EventDetailFacilitiesLabels labels;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;
    final facilities = event.facilities!;
    final themeColor = theme.colorScheme.primary;

    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 48),
      child: Column(
        children: [
          Text(
            labels.title,
            style: theme.textTheme.sectionTitle(isMobile: isMobile),
          ),
          const SizedBox(height: 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: isMobile
                ? Column(
                    children: [
                      for (int i = 0; i < facilities.length; i++) ...[
                        if (i > 0) const SizedBox(height: 16),
                        PublicEventFacilityCard(
                          facility: facilities[i],
                          color: themeColor,
                        ),
                      ],
                    ],
                  )
                : IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (int i = 0; i < facilities.length; i++) ...[
                          if (i > 0) const SizedBox(width: 24),
                          Expanded(
                            child: PublicEventFacilityCard(
                              facility: facilities[i],
                              color: themeColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
