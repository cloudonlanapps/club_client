import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show DateDayLabel;

import 'occurrence_tile.dart';

/// Data for a single occurrence within a day group.
class OccurrenceEntry {
  const OccurrenceEntry({
    required this.eventTitle,
    required this.eventType,
    this.attendanceStatus,
    this.timeRange,
    this.onTap,
  });

  final String eventTitle;
  final EventType eventType;
  final AttendanceStatus? attendanceStatus;
  final String? timeRange;
  final VoidCallback? onTap;
}

/// Card for a single day containing all occurrence rows for that date.
///
/// Displays a DateDayLabel on the left and stacks OccurrenceTile widgets
/// vertically on the right. Days without occurrences are skipped entirely.
class AttendanceDayGroup extends StatelessWidget {
  const AttendanceDayGroup({
    required this.date,
    required this.entries,
    super.key,
  });

  final DateTime date;
  final List<OccurrenceEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DateDayLabel(date: date),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < entries.length; i++) ...[
                    OccurrenceTile(
                      eventTitle: entries[i].eventTitle,
                      eventType: entries[i].eventType,
                      attendanceStatus: entries[i].attendanceStatus,
                      timeRange: entries[i].timeRange,
                      onTap: entries[i].onTap,
                    ),
                    if (i < entries.length - 1)
                      Divider(
                        height: 12,
                        thickness: 0.5,
                        color: theme.colorScheme.border,
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
