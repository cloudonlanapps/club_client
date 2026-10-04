import 'package:club_sdk_2/club_sdk_2.dart' show EventType;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/public/public_event_view.dart';
import '../public_event_card.dart';
import 'public_events_section_header.dart';
import 'public_events_section_reveal.dart';

/// A landing page section of one event type: header, a few teaser cards and
/// a "see all" button.
///
/// The host picks the [events] (`selectLandingEvents`), supplies the copy and
/// navigates: [onSeeAll] from the badge and the button, [onEventTap] from a
/// card. Parts slide in once [visible].
class PublicEventsSection extends StatelessWidget {
  const PublicEventsSection({
    required this.type,
    required this.events,
    required this.badge,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onSeeAll,
    required this.onEventTap,
    this.cardLabels = const {},
    this.visible = true,
    super.key,
  });

  /// Narrower than this is laid out for a phone.
  static const double mobileBreakpoint = 768;

  /// Widest the cards grow.
  static const double maxCardsWidth = 1000;

  /// The events' type; a programme section leaves more room above its button.
  final EventType type;

  final List<PublicEventView> events;
  final String badge;
  final String title;
  final String description;
  final String buttonText;

  /// Called by the badge and the button: the full listing.
  final VoidCallback onSeeAll;

  /// Called with a tapped card's public id.
  final ValueChanged<String> onEventTap;

  /// Label text by `PublicEventCardLabels` key.
  final Map<String, String> cardLabels;

  /// Whether the section has scrolled into view.
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < mobileBreakpoint;
    final isProgramme = type == EventType.programme;

    return Column(
      children: [
        PublicEventsSectionHeader(
          badge: badge,
          title: title,
          description: description,
          isMobile: isMobile,
          visible: visible,
          onBadgeTap: onSeeAll,
        ),
        SizedBox(height: isMobile ? 40 : 60),
        PublicEventsSectionReveal(
          visible: visible,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxCardsWidth),
            child: Column(
              children: [
                for (final event in events)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: PublicEventCard(
                      event: event,
                      cardLabels: cardLabels,
                      showFeatures: false,
                      showFees: false,
                      showPrimaryButton: false,
                      onTap: () => onEventTap(event.publicId),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: isProgramme ? (isMobile ? 40 : 60) : (isMobile ? 20 : 40),
        ),
        PublicEventsSectionReveal(
          visible: visible,
          child: Center(
            child: ShadButton(
              onPressed: onSeeAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(buttonText),
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.arrowRight, size: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
