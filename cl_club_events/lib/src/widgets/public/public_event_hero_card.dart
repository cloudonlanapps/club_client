import 'package:club_sdk_2/club_sdk_2.dart' show EventType;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ClubTextTheme, StampBadge;

import '../../extensions/public_event_view_dates.dart';
import '../../extensions/public_event_view_timing.dart';
import '../../models/public/public_event_view.dart';
import 'event_info_chip.dart';

/// A public event on a translucent card, for the landing hero carousel over
/// a full-screen background.
class PublicEventHeroCard extends StatelessWidget {
  const PublicEventHeroCard({
    required this.event,
    this.buttonText = 'Learn More',
    this.onButtonPressed,
    this.compact = false,
    super.key,
  });

  final PublicEventView event;
  final String buttonText;

  /// The button's action; no button without one.
  final VoidCallback? onButtonPressed;

  /// The phone layout.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final stamp = event.stamp;
    final tagline = event.tagline;

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.card.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (stamp != null) ...[
            StampBadge(text: stamp),
            const SizedBox(height: 12),
          ],
          Text(
            event.title,
            style: theme.textTheme
                .cardTitle(compact: compact)
                .copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.cardForeground,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (tagline != null) ...[
            const SizedBox(height: 8),
            Text(
              tagline,
              style: theme.textTheme.heroSubtitle(
                isMobile: compact,
                color: theme.colorScheme.mutedForeground,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              if (event.type == EventType.programme) ...[
                if (event.effectiveSchedule case final schedule?)
                  EventInfoChip(icon: LucideIcons.calendar, text: schedule),
                if (event.effectiveDuration case final duration?)
                  EventInfoChip(icon: LucideIcons.clock, text: duration),
              ] else ...[
                EventInfoChip(
                  icon: LucideIcons.calendar,
                  text: event.displayDateRange,
                ),
                EventInfoChip(
                  icon: LucideIcons.mapPin,
                  text: event.venueDisplay,
                ),
              ],
            ],
          ),
          if (onButtonPressed != null) ...[
            SizedBox(height: compact ? 12 : 16),
            Align(
              alignment: Alignment.centerRight,
              child: ShadButton(
                size: compact ? ShadButtonSize.sm : ShadButtonSize.regular,
                onPressed: onButtonPressed,
                child: Text(buttonText),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
