import 'package:club_sdk_2/club_sdk_2.dart' show PromotionalOffer;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ThemedMarkdown;

import '../../../utils/public_event_format.dart';

class PublicEventOfferCard extends StatelessWidget {
  const PublicEventOfferCard({
    required this.offer,
    required this.validUntilPrefix,
    super.key,
  });
  final PromotionalOffer offer;
  final String validUntilPrefix;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    LucideIcons.tag,
                    size: 24,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(offer.title, style: theme.textTheme.h4)),
              ],
            ),
            if (offer.description != null) ...[
              const SizedBox(height: 12),
              ThemedMarkdown(
                data: offer.description!,
                selectable: false,
                textStyle: theme.textTheme.muted.copyWith(height: 1.5),
              ),
            ],
            if (offer.validUntilUtc != null) ...[
              const SizedBox(height: 8),
              Text(
                '$validUntilPrefix${formatLongDate(offer.validUntilUtc!)}',
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.mutedForeground,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
