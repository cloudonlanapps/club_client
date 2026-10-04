import 'package:flutter/widgets.dart';

import '../../models/public/public_event_view.dart';
import 'public_event_card.dart';

/// A column of [PublicEventCard]s: the live programmes, camps or one-offs.
class PublicEventCardList extends StatelessWidget {
  const PublicEventCardList({
    required this.events,
    required this.onEventTap,
    this.cardLabels = const {},
    super.key,
  });

  /// Widest the list grows.
  static const double maxWidth = 1000;

  /// Gap below each card.
  static const double gap = 24;

  final List<PublicEventView> events;

  /// Called with the tapped event's public id.
  final ValueChanged<String> onEventTap;

  /// Label text by `PublicEventCardLabels` key.
  final Map<String, String> cardLabels;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      child: Column(
        children: [
          for (final event in events)
            Padding(
              padding: const EdgeInsets.only(bottom: gap),
              child: PublicEventCard(
                event: event,
                cardLabels: cardLabels,
                onTap: () => onEventTap(event.publicId),
              ),
            ),
        ],
      ),
    );
  }
}
