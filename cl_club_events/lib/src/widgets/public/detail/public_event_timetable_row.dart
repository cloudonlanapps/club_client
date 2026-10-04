import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/public/event_time_slot.dart';

/// One timetable row: the session's name and its clock range.
class PublicEventTimetableRow extends StatelessWidget {
  const PublicEventTimetableRow({required this.slot, super.key});

  final EventTimeSlot slot;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final themeColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Session label (e.g., "Off-Ice Workout")
          Expanded(
            child: Text(
              slot.label ?? '',
              style: theme.textTheme.p.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          // Timing badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              slot.range,
              style: theme.textTheme.small.copyWith(
                fontWeight: FontWeight.w500,
                color: themeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
