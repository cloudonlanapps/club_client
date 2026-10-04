import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ClubTextTheme;

import '../../../extensions/public_event_view_dates.dart';
import '../../../models/public/detail_labels/event_detail_fees_labels.dart';
import '../../../models/public/public_event_view.dart';

class PublicEventFeesSection extends StatelessWidget {
  const PublicEventFeesSection({
    required this.event,
    required this.labels,
    super.key,
  });
  final PublicEventView event;
  final EventDetailFeesLabels labels;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;
    final themeColor = theme.colorScheme.primary;
    final includes = event.includes ?? [];

    if (event.fees == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
        horizontal: isMobile ? 24 : 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ShadCard(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Text(
                    labels.title,
                    style: theme.textTheme.subsectionTitle(isMobile: isMobile),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    event.formattedFees,
                    style: theme.textTheme.priceHero(
                      isMobile: isMobile,
                      color: themeColor,
                    ),
                  ),
                  if (includes.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      labels.includesLabel,
                      style: theme.textTheme.small.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...includes.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.circleCheck,
                              size: 16,
                              color: themeColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item,
                                style: theme.textTheme.p.copyWith(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
