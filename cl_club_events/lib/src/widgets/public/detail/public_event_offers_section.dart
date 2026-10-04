import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ClubTextTheme;

import '../../../models/public/detail_labels/event_detail_offers_labels.dart';
import '../../../models/public/public_event_view.dart';
import 'public_event_offer_card.dart';

class PublicEventOffersSection extends StatelessWidget {
  const PublicEventOffersSection({
    required this.event,
    required this.labels,
    super.key,
  });
  final PublicEventView event;
  final EventDetailOffersLabels labels;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;
    final offers = event.offers!;
    final themeColor = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 48),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.tag, size: 28, color: themeColor),
              const SizedBox(width: 12),
              Text(
                labels.title,
                style: theme.textTheme.sectionTitle(isMobile: isMobile),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: isMobile
                ? Column(
                    children: [
                      for (int i = 0; i < offers.length; i++) ...[
                        if (i > 0) const SizedBox(height: 16),
                        PublicEventOfferCard(
                          offer: offers[i],
                          validUntilPrefix: labels.validUntilPrefix,
                        ),
                      ],
                    ],
                  )
                : IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (int i = 0; i < offers.length; i++) ...[
                          if (i > 0) const SizedBox(width: 24),
                          Expanded(
                            child: PublicEventOfferCard(
                              offer: offers[i],
                              validUntilPrefix: labels.validUntilPrefix,
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
