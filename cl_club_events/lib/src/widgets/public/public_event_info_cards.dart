import 'package:club_sdk_2/club_sdk_2.dart' show EventType;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import '../../extensions/public_event_view_dates.dart';
import '../../extensions/public_event_view_timing.dart';
import '../../models/public/detail_labels/event_detail_hero_labels.dart';
import '../../models/public/public_event_view.dart';
import 'event_info_badge.dart';

/// A public event's dates, timings and venue as info badges, at the top of
/// its detail page.
///
/// Dates are a camp's or one-off's range and a programme's schedule. The
/// venue badge calls [onVenueTap] with the venue's public id.
class PublicEventInfoCards extends StatelessWidget {
  const PublicEventInfoCards({
    required this.event,
    required this.labels,
    this.onVenueTap,
    super.key,
  });

  /// Narrower than this is laid out for a phone.
  static const double mobileBreakpoint = 768;

  final PublicEventView event;
  final EventDetailHeroLabels labels;

  /// Called with the venue's public id when its badge is tapped.
  final ValueChanged<String>? onVenueTap;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < mobileBreakpoint;
    final timings = event.effectiveTimings;
    final venueName = event.venue.name;
    final dateValue = event.type == EventType.programme
        ? event.effectiveSchedule
        : event.displayDateRange;
    final venueTap = onVenueTap;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: isMobile ? 8 : 16,
      runSpacing: isMobile ? 8 : 12,
      children: [
        if (dateValue != null && dateValue.isNotEmpty)
          EventInfoBadge(
            icon: LucideIcons.calendar,
            label: labels.datesLabel,
            value: dateValue,
            isMobile: isMobile,
          ),
        if (timings.isNotEmpty)
          EventInfoBadge(
            icon: LucideIcons.clock,
            label: labels.timingsLabel,
            value: timings.join('\n'),
            isMobile: isMobile,
          ),
        if (venueName.isNotEmpty)
          GestureDetector(
            onTap: venueTap == null ? null : () => venueTap(event.venueId),
            child: MouseRegion(
              cursor: venueTap == null
                  ? MouseCursor.defer
                  : SystemMouseCursors.click,
              child: EventInfoBadge(
                icon: LucideIcons.mapPin,
                label: labels.venueLabel,
                value: venueName,
                isMobile: isMobile,
              ),
            ),
          ),
      ],
    );
  }
}
