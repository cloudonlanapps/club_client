import 'package:cl_calendar/cl_calendar.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../providers/cached_date_items.dart';
import '../providers/selected_occurrence.dart';
import '../utils/session_lanes.dart';
import 'calendar_session_block.dart';

/// Renders a half-hour cell of the week view, coloured by the sessions at
/// this time: each a [CalendarSessionBlock], striped when the session was
/// cancelled (club_client#419). Sessions that overlap sit side by side in
/// lanes worked out for the whole day ([sessionLanes]), so a session keeps
/// its lane in every cell it covers, and each lane is its own tap target
/// (club_client#420). Used as slotBuilder for WeekGrid/DayGrid.
class CalendarSlotView extends ConsumerWidget {
  const CalendarSlotView({
    required this.slotTime,
    required this.size,
    required this.range,
    required this.selectedDateTime,
    required this.onChangeSelectedDateTime,
    super.key,
  });

  final DateTime slotTime;
  final Size size;
  final CalendarViewRange range;
  final DateTime selectedDateTime;
  final void Function(DateTime) onChangeSelectedDateTime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GetReferenceDateTimeUtc(
      builder: (refDate) {
        final theme = ShadTheme.of(context);
        final date = DateUtils.dateOnly(slotTime);

        final cached = ref.watch(
          cachedDateItemsProvider((
            date: date,
            range: range,
          )),
        );
        final items = cached.data ?? [];

        final selectedKey = ref.watch(selectedOccurrenceProvider);
        final now = refDate ?? DateTime.now().toUtc();

        // The day's sessions in their lanes; this cell draws those it
        // overlaps, each in its lane's share of the width.
        final inCell = sessionLanes(
          items,
        ).where((l) => isInSlot(l.item.$1, slotTime));

        final isSelectedDay = DateUtils.isSameDay(selectedDateTime, slotTime);
        final isInSelectedHour =
            isSelectedDay && slotTime.hour == selectedDateTime.hour;

        return GestureDetector(
          // A tap on a part of the cell no session covers.
          onTap: () => handleTap(ref, null),
          child: Container(
            width: size.width,
            height: size.height,
            color: isInSelectedHour
                ? theme.colorScheme.selection.withValues(alpha: 0.3)
                : null,
            child: Stack(
              children: [
                for (final l in inCell)
                  Positioned(
                    left: size.width * l.lane / l.lanes,
                    width: size.width / l.lanes,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => handleTap(ref, l.item.$1),
                      child: CalendarSessionBlock(
                        cancelled:
                            l.item.$1.status == OccurrenceStatus.cancelled,
                        selected:
                            selectedKey?.eventId == l.item.$1.eventId &&
                            selectedKey?.originalStartTime ==
                                l.item.$1.originalStartTimeUtc,
                        past: l.item.$1.actualEndTimeUtc.isBefore(now),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Check if the occurrence overlaps with this 30-min slot.
  bool isInSlot(Occurrence occurrence, DateTime slot) {
    final occStart = occurrence.actualStartTimeUtc.toLocal();
    final occEnd = occurrence.actualEndTimeUtc.toLocal();
    final slotEnd = slot.add(const Duration(minutes: 30));
    return occStart.isBefore(slotEnd) && occEnd.isAfter(slot);
  }

  void handleTap(WidgetRef ref, Occurrence? occurrence) {
    onChangeSelectedDateTime(slotTime);
    if (occurrence != null) {
      ref.read(selectedOccurrenceProvider.notifier).state = (
        eventId: occurrence.eventId,
        originalStartTime: occurrence.originalStartTimeUtc,
      );
    } else {
      ref.read(selectedOccurrenceProvider.notifier).state = null;
    }
  }
}
