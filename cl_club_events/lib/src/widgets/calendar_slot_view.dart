import 'package:cl_calendar/cl_calendar.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../providers/cached_date_items.dart';
import '../providers/selected_occurrence.dart';

/// Renders a colored cell based on events at this time slot.
/// Used as slotBuilder for WeekGrid/DayGrid.
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

        // Find item that overlaps with this slot
        final item = items.firstWhereOrNull(
          (item) => isInSlot(item.$1, slotTime),
        );

        final occurrence = item?.$1;
        final event = item?.$2;

        final isSelected =
            occurrence != null &&
            selectedKey?.eventId == occurrence.eventId &&
            selectedKey?.originalStartTime == occurrence.originalStartTimeUtc;

        final isSelectedDay = DateUtils.isSameDay(selectedDateTime, slotTime);
        final isInSelectedHour =
            isSelectedDay && slotTime.hour == selectedDateTime.hour;

        Color? backgroundColor;
        if (occurrence != null && event != null) {
          final effectiveRefDate = refDate ?? DateTime.now().toUtc();
          final isPast = occurrence.actualEndTimeUtc.isBefore(effectiveRefDate);
          backgroundColor = theme.colorScheme.primary.withValues(
            alpha: isSelected ? (isPast ? 0.5 : 0.9) : (isPast ? 0.2 : 0.6),
          );
        } else if (isInSelectedHour) {
          backgroundColor = theme.colorScheme.selection.withValues(alpha: 0.3);
        }

        return GestureDetector(
          onTap: () => handleTap(ref, occurrence),
          child: Container(
            width: size.width,
            height: size.height,
            color: backgroundColor,
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
