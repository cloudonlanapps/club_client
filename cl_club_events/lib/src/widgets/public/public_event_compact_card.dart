import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../extensions/public_event_view_dates.dart';
import '../../models/public/public_event_card_labels.dart';
import '../../models/public/public_event_view.dart';
import 'public_event_card_image.dart';
import 'public_event_card_info_row.dart';
import 'public_event_status_pill.dart';

/// The compact tile of a public event, for the grid of past events.
///
/// The cover (when there is one) over a `Past` pill, the title, the dates
/// and the photo count. Tapping it calls [onTap].
///
/// On a phone it fills the width less the page gutter; wider, it is 340 px.
class PublicEventCompactCard extends StatelessWidget {
  const PublicEventCompactCard({
    required this.event,
    this.onTap,
    this.cardLabels = const {},
    super.key,
  });

  /// Narrower than this is laid out for a phone.
  static const double mobileBreakpoint = 768;

  /// Width of the tile on a wide screen.
  static const double desktopWidth = 340;

  /// The page gutter a phone tile leaves.
  static const double mobileGutter = 48;

  final PublicEventView event;

  /// Called when the tile is tapped.
  final VoidCallback? onTap;

  /// Label text by `PublicEventCardLabels` key.
  final Map<String, String> cardLabels;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = screenWidth < mobileBreakpoint
        ? screenWidth - mobileGutter
        : desktopWidth;
    final isPast = event.isPast;
    final photoCount = event.galleryUris.length;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: isPast ? 0.8 : 1.0,
          child: ShadCard(
            width: cardWidth,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (event.imageUri != null)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: PublicEventCardImage(
                      event: event,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPast) ...[
                        PublicEventStatusPill(
                          text: PublicEventCardLabels.of(
                            cardLabels,
                            PublicEventCardLabels.past,
                          ),
                          backgroundColor: theme.colorScheme.foreground
                              .withValues(alpha: 0.08),
                          foregroundColor: theme.colorScheme.mutedForeground,
                        ),
                        const SizedBox(height: 10),
                      ],
                      Text(
                        event.title,
                        style: theme.textTheme.h4.copyWith(
                          fontSize: 16,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      PublicEventCardInfoRow(
                        icon: LucideIcons.calendar,
                        text: event.dateRange,
                      ),
                      if (photoCount > 0) ...[
                        const SizedBox(height: 8),
                        PublicEventCardInfoRow(
                          icon: LucideIcons.images,
                          text: '$photoCount photos',
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
