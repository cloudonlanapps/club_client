import 'package:flutter/widgets.dart';

import '../../models/public/public_event_view.dart';
import 'public_event_compact_card.dart';

/// A wrapping grid of [PublicEventCompactCard]s: the past events.
class PublicEventCardGrid extends StatelessWidget {
  const PublicEventCardGrid({
    required this.events,
    required this.onEventTap,
    this.cardLabels = const {},
    super.key,
  });

  /// Gap between tiles.
  static const double gap = 24;

  final List<PublicEventView> events;

  /// Called with the tapped event's public id.
  final ValueChanged<String> onEventTap;

  /// Label text by `PublicEventCardLabels` key.
  final Map<String, String> cardLabels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final event in events)
          PublicEventCompactCard(
            event: event,
            cardLabels: cardLabels,
            onTap: () => onEventTap(event.publicId),
          ),
      ],
    );
  }
}
