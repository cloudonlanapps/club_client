import 'package:club_sdk_2/club_sdk_2.dart' show EventConflictItem, EventType;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../utils/schedule_clash_window.dart';

/// One clashing event in the schedule clash dialog: its title and type,
/// then the dates and times of its sessions that overlap the schedule being
/// saved, at most [maxListedWindows] of them and a count of the rest.
class ScheduleClashItem extends StatelessWidget {
  /// Shows the clashing event [item].
  const ScheduleClashItem({required this.item, super.key});

  /// The clashing event and its overlapping sessions.
  final EventConflictItem item;

  /// How many overlapping sessions are listed before the rest are counted.
  static const int maxListedWindows = 5;

  /// Shown for a clashing event the report gives no title.
  static const String untitledEvent = 'Untitled event';

  /// Separates the title from the event type.
  static const String typeSeparator = ' · ';

  /// The line counting the overlapping sessions not listed.
  static String moreWindows(int count) =>
      'and $count more ${count == 1 ? 'session' : 'sessions'}';

  /// How the event type the report names reads, or `null` when it names
  /// none the club knows.
  static String? typeLabelOf(String eventType) =>
      switch (EventType.values.asNameMap()[eventType]) {
        EventType.programme => 'Programme',
        EventType.camp => 'Camp',
        EventType.oneOff => 'One-off',
        null => null,
      };

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final title = item.eventTitle.trim().isEmpty
        ? untitledEvent
        : item.eventTitle;
    final type = typeLabelOf(item.eventType);
    final listed = item.occurrences.take(maxListedWindows);
    final unlisted = item.occurrences.length - listed.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          type == null ? title : '$title$typeSeparator$type',
          style: theme.textTheme.p,
        ),
        for (final pair in listed)
          Text(
            scheduleClashWindowLabel(pair.otherStartUtc, pair.otherEndUtc),
            style: theme.textTheme.muted,
          ),
        if (unlisted > 0)
          Text(moreWindows(unlisted), style: theme.textTheme.muted),
      ],
    );
  }
}
