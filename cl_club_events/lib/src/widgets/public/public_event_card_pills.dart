import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/public/public_event_card_labels.dart';
import '../../models/public/public_event_view.dart';
import 'public_event_status_pill.dart';

/// The pills at the top of a public event card: the event's stamp (while it
/// is live) and its registration state.
class PublicEventCardPills extends StatelessWidget {
  const PublicEventCardPills({
    required this.event,
    this.cardLabels = const {},
    super.key,
  });

  final PublicEventView event;

  /// Label text by `PublicEventCardLabels` key.
  final Map<String, String> cardLabels;

  @override
  Widget build(BuildContext context) {
    final colors = ShadTheme.of(context).colorScheme;
    final isPast = event.isPast;
    final isClosed = event.isRegistrationClosed;
    final isInactive = isPast || isClosed;
    final stamp = event.stamp;

    final statusText = PublicEventCardLabels.of(
      cardLabels,
      isPast
          ? PublicEventCardLabels.past
          : isClosed
          ? PublicEventCardLabels.registrationsClosed
          : PublicEventCardLabels.registrationsOpen,
    );

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        if (stamp != null && !isPast)
          PublicEventStatusPill(
            text: stamp.toUpperCase(),
            backgroundColor: PublicEventStatusPill.stampBackground,
            foregroundColor: PublicEventStatusPill.stampForeground,
          ),
        PublicEventStatusPill(
          text: statusText,
          backgroundColor: isInactive
              ? colors.foreground.withValues(alpha: 0.08)
              : colors.primary.withValues(alpha: 0.15),
          foregroundColor: isInactive ? colors.mutedForeground : colors.primary,
        ),
      ],
    );
  }
}
