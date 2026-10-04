import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ClubTextTheme;

import '../../../models/public/detail_labels/event_detail_eligibility_labels.dart';
import '../../../models/public/public_event_view.dart';

class PublicEventEligibilitySection extends StatelessWidget {
  const PublicEventEligibilitySection({
    required this.event,
    required this.labels,
    super.key,
  });
  final PublicEventView event;
  final EventDetailEligibilityLabels labels;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    if (event.eligibility == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
        horizontal: isMobile ? 24 : 48,
      ),
      child: Center(
        child: Column(
          children: [
            Text(
              labels.title,
              style: theme.textTheme.subsectionTitle(isMobile: isMobile),
            ),
            const SizedBox(height: 16),
            Text(
              event.eligibility!,
              style: theme.textTheme.h4,
              textAlign: TextAlign.center,
            ),
            if (event.eligibilityNote != null) ...[
              const SizedBox(height: 8),
              Text(
                '(${event.eligibilityNote})',
                style: theme.textTheme.muted,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
