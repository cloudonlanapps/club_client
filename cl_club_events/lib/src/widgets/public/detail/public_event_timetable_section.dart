import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ClubTextTheme;

import '../../../extensions/public_event_view_timing.dart';
import '../../../models/public/detail_labels/event_detail_batch_timings_labels.dart';
import '../../../models/public/public_event_view.dart';
import 'public_event_timetable_row.dart';

/// The ordered timetable inside one occurrence.
///
/// This was the batch timings table. Batches are gone from the server: an
/// event carries an ordered `sessions` list whose periods sum to the
/// occurrence window, and the same rows fall out of walking it.
class PublicEventTimetableSection extends StatelessWidget {
  const PublicEventTimetableSection({
    required this.event,
    required this.labels,
    super.key,
  });
  final PublicEventView event;
  final EventDetailBatchTimingsLabels labels;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 48),
      child: Column(
        children: [
          Text(
            labels.title,
            style: theme.textTheme.sectionTitle(isMobile: isMobile),
          ),
          const SizedBox(height: 8),
          if (event.effectiveSchedule != null)
            Text(
              event.effectiveSchedule!,
              style: theme.textTheme.muted.copyWith(
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: ShadCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: event.timetable
                    .map((slot) => PublicEventTimetableRow(slot: slot))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
