import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/public/public_event_view.dart';
import 'public_event_card_content.dart';
import 'public_event_card_image.dart';

/// The public event card: the cover beside (or above) the event's facts,
/// description and a single call to action.
///
/// - The cover is purely presentational; with no cover the content fills
///   the card.
/// - Phone (`width < 768`): cover on top (16:9), content below.
/// - Wider: cover on the left (280 px), stretched to the content's height.
///
/// Tapping the card, or its button, calls [onTap]; the host navigates.
class PublicEventCard extends StatelessWidget {
  const PublicEventCard({
    required this.event,
    this.onTap,
    this.cardLabels = const {},
    this.showFeatures = true,
    this.showFees = true,
    this.showPrimaryButton = true,
    super.key,
  });

  /// Narrower than this is laid out for a phone.
  static const double mobileBreakpoint = 768;

  /// Width of the cover on a wide screen.
  static const double desktopImageWidth = 280;

  final PublicEventView event;

  /// Called when the card or its button is tapped.
  final VoidCallback? onTap;

  /// Label text by `PublicEventCardLabels` key.
  final Map<String, String> cardLabels;

  /// When false, hides the "What's Included" list on programme cards.
  final bool showFeatures;

  /// When false, hides the fee on camp / one-off cards.
  final bool showFees;

  /// When false, hides the call to action (View Details / View Gallery).
  final bool showPrimaryButton;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < mobileBreakpoint;

    final content = PublicEventCardContent(
      event: event,
      onViewDetails: onTap,
      cardLabels: cardLabels,
      showFeatures: showFeatures,
      showFees: showFees,
      showPrimaryButton: showPrimaryButton,
    );

    final Widget body;
    if (event.imageUri == null) {
      body = content;
    } else if (isMobile) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: PublicEventCardImage(
              event: event,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
          ),
          content,
        ],
      );
    } else {
      // IntrinsicHeight bounds the row at the content's height and
      // CrossAxisAlignment.stretch makes the cover fill it; the cover reports
      // no intrinsic height of its own (see PublicEventCardImage).
      body = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: desktopImageWidth,
              child: PublicEventCardImage(
                event: event,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
              ),
            ),
            Expanded(child: content),
          ],
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: event.isPast ? 0.75 : 1.0,
          child: ShadCard(padding: EdgeInsets.zero, child: body),
        ),
      ),
    );
  }
}
