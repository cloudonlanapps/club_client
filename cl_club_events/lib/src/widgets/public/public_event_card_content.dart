import 'package:club_sdk_2/club_sdk_2.dart' show EventType;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ClubTextTheme, ThemedMarkdown;

import '../../extensions/public_event_view_dates.dart';
import '../../models/public/public_event_card_labels.dart';
import '../../models/public/public_event_view.dart';
import 'public_event_card_facts.dart';
import 'public_event_card_features.dart';
import 'public_event_card_pills.dart';

/// The text column of a `PublicEventCard`, the same beside or under the
/// cover:
///
/// 1. stamp and registration-state pills
/// 2. title and tagline
/// 3. when and where
/// 4. description (markdown)
/// 5. "For ages X"
/// 6. "What's Included" (programmes)
/// 7. fee (camps and one-offs, while live)
/// 8. photo count (past events)
/// 9. one call to action: View Details, or View Gallery once past
class PublicEventCardContent extends StatelessWidget {
  const PublicEventCardContent({
    required this.event,
    this.onViewDetails,
    this.cardLabels = const {},
    this.showFeatures = true,
    this.showFees = true,
    this.showPrimaryButton = true,
    super.key,
  });

  final PublicEventView event;

  /// Called by the call-to-action button.
  final VoidCallback? onViewDetails;

  /// Label text by `PublicEventCardLabels` key.
  final Map<String, String> cardLabels;

  /// When false, hides the "What's Included" list on programme cards.
  final bool showFeatures;

  /// When false, hides the fee on camp / one-off cards.
  final bool showFees;

  /// When false, hides the call to action.
  final bool showPrimaryButton;

  /// The card label for [key].
  String label(String key) => PublicEventCardLabels.of(cardLabels, key);

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isProgram = event.type == EventType.programme;
    final isPast = event.isPast;
    final description = event.description;
    final ageRange = event.ageRange;
    final tagline = event.tagline;
    final features = event.highlights ?? const <String>[];
    final photoCount = event.galleryUris.length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          PublicEventCardPills(event: event, cardLabels: cardLabels),
          const SizedBox(height: 16),
          Text(event.title, style: theme.textTheme.h3.copyWith(height: 1.2)),
          if (tagline != null && tagline.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              tagline,
              style: theme.textTheme.muted.copyWith(
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 18),
          PublicEventCardFacts(event: event, cardLabels: cardLabels),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 18),
            ThemedMarkdown(
              data: description,
              selectable: false,
              textAlign: TextAlign.justify,
              textStyle: theme.textTheme.p.copyWith(height: 1.55),
            ),
          ],
          if (ageRange != null && ageRange.isNotEmpty) ...[
            SizedBox(height: description.isNotEmpty ? 8 : 18),
            Text(
              '${label(PublicEventCardLabels.ageRangePrefix)}$ageRange',
              style: theme.textTheme.muted.copyWith(fontSize: 13),
            ),
          ],
          if (isProgram && showFeatures && features.isNotEmpty) ...[
            const SizedBox(height: 18),
            PublicEventCardFeatures(
              title: label(PublicEventCardLabels.whatsIncluded),
              features: features,
            ),
          ],
          if (!isProgram && showFees && !isPast && event.fees != null) ...[
            const SizedBox(height: 18),
            Text(
              event.formattedFees,
              style: theme.textTheme.priceSmall(theme.colorScheme.primary),
            ),
          ],
          if (isPast && photoCount > 0) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  LucideIcons.images,
                  size: 16,
                  color: theme.colorScheme.mutedForeground,
                ),
                const SizedBox(width: 8),
                Text(
                  '$photoCount photos from the event',
                  style: theme.textTheme.muted,
                ),
              ],
            ),
          ],
          if (showPrimaryButton) ...[
            const SizedBox(height: 22),
            ShadButton(
              onPressed: onViewDetails,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label(
                      isPast
                          ? PublicEventCardLabels.viewGallery
                          : PublicEventCardLabels.viewDetails,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.arrowRight, size: 16),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
