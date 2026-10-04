import 'package:flutter/widgets.dart';
import 'package:ui_lib/ui_lib.dart' show StatusBadge;

import 'venue_card_description.dart';

/// The body of a venue card: a description preview over its badges.
///
/// Renders nothing when there is neither.
class VenueCardBody extends StatelessWidget {
  const VenueCardBody({
    this.description,
    this.badges = const [],
    super.key,
  });

  /// The venue's description, as markdown.
  final String? description;

  /// Badge labels, each shown as a bordered, uncoloured [StatusBadge].
  final List<String> badges;

  @override
  Widget build(BuildContext context) {
    final text = description;
    final hasDescription = text != null && text.isNotEmpty;
    if (badges.isEmpty && !hasDescription) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasDescription) VenueCardDescription(description: text),
        if (badges.isNotEmpty) ...[
          if (hasDescription) const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [for (final label in badges) StatusBadge(label: label)],
          ),
        ],
      ],
    );
  }
}
