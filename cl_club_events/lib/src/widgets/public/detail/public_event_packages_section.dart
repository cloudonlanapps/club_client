import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ClubTextTheme, ThemedMarkdown;

import '../../../models/public/detail_labels/event_detail_packages_labels.dart';
import '../../../models/public/public_event_view.dart';
import '../../../utils/public_event_format.dart';

class PublicEventPackagesSection extends StatelessWidget {
  const PublicEventPackagesSection({
    required this.event,
    required this.labels,
    super.key,
  });
  final PublicEventView event;
  final EventDetailPackagesLabels labels;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;
    final themeColor = theme.colorScheme.primary;

    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 48),
      child: Column(
        children: [
          Text(
            labels.title,
            style: theme.textTheme.sectionTitle(isMobile: isMobile),
          ),
          const SizedBox(height: 8),
          Text(labels.subtitle, style: theme.textTheme.muted),
          const SizedBox(height: 32),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 24,
            children: event.packageOffers!.map((offer) {
              return ShadCard(
                width: isMobile ? screenWidth - 48 : 280,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(offer.name, style: theme.textTheme.h3),
                      if (offer.description != null) ...[
                        const SizedBox(height: 8),
                        ThemedMarkdown(
                          data: offer.description!,
                          selectable: false,
                          textStyle: theme.textTheme.muted,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        '$kCurrencySymbol${formatThousands(offer.price)}/-',
                        style: theme.textTheme.priceMedium(themeColor),
                      ),
                      if (offer.features != null &&
                          offer.features!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ...offer.features!.map(
                          (feature) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.check,
                                  size: 14,
                                  color: themeColor,
                                ),
                                const SizedBox(width: 6),
                                Text(feature, style: theme.textTheme.small),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
