import 'package:club_sdk_2/club_sdk_2.dart' show EventType;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import '../../extensions/public_event_view_dates.dart';
import '../../extensions/public_event_view_timing.dart';
import '../../models/public/public_event_card_labels.dart';
import '../../models/public/public_event_view.dart';
import 'public_event_card_info_row.dart';

/// When and where, as icon rows: a programme's days and hours, or a camp's
/// dates and first timing; then the venue.
class PublicEventCardFacts extends StatelessWidget {
  const PublicEventCardFacts({
    required this.event,
    this.cardLabels = const {},
    super.key,
  });

  final PublicEventView event;

  /// Label text by `PublicEventCardLabels` key.
  final Map<String, String> cardLabels;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    if (event.type == EventType.programme) {
      final schedule = event.effectiveSchedule;
      final duration = event.effectiveDuration;
      if (schedule != null) {
        rows.add(
          PublicEventCardInfoRow(icon: LucideIcons.calendar, text: schedule),
        );
      }
      if (duration != null) {
        rows.add(
          PublicEventCardInfoRow(icon: LucideIcons.clock, text: duration),
        );
      }
    } else {
      rows.add(
        PublicEventCardInfoRow(
          icon: LucideIcons.calendar,
          text: event.dateRange,
        ),
      );
      final timings = event.effectiveTimings;
      if (timings.isNotEmpty) {
        rows.add(
          PublicEventCardInfoRow(icon: LucideIcons.clock, text: timings.first),
        );
      }
    }
    rows.add(
      PublicEventCardInfoRow(
        icon: LucideIcons.mapPin,
        text: event.venueDisplay.isNotEmpty
            ? event.venueDisplay
            : PublicEventCardLabels.of(
                cardLabels,
                PublicEventCardLabels.venueTbd,
              ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: rows,
    );
  }
}
