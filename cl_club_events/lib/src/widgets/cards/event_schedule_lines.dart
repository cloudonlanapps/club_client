import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../utils/time_formatter.dart';

/// Time + recurrence display for EventCard.
///
/// When [wrap] is false, time and recurrence render on a single row separated
/// by a gap. When [wrap] is true, the recurrence drops to its own line below
/// the time so neither truncates on narrow screens.
class EventScheduleLines extends StatelessWidget {
  const EventScheduleLines({
    required this.event,
    required this.wrap,
    super.key,
  });

  final Event event;
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final muted = theme.colorScheme.mutedForeground;
    final textStyle = theme.textTheme.small.copyWith(color: muted);

    final timeText = formatTimeRange(event.startTimeUtc, event.endTimeUtc);
    final ruleText = eventScheduleSummary(event);

    final timePart = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.clock, size: 12, color: muted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            timeText,
            style: textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (ruleText == null) return timePart;

    final rulePart = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.calendar, size: 12, color: muted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            ruleText,
            style: textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (wrap) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          timePart,
          const SizedBox(height: 4),
          rulePart,
        ],
      );
    }

    return Row(
      children: [
        timePart,
        const SizedBox(width: 12),
        Flexible(child: rulePart),
      ],
    );
  }
}
