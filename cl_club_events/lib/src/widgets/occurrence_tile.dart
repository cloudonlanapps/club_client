import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Compact row displaying an occurrence with event title, time range,
/// and a descriptive attendance status message.
///
/// Layout:
/// - Line 1: Event title
/// - Line 2: Time range (right-aligned, muted)
/// - Line 3: Badge code + status message (right-aligned, italic)
///
/// Used within AttendanceDayGroup to show multiple occurrences per day.
class OccurrenceTile extends StatelessWidget {
  const OccurrenceTile({
    required this.eventTitle,
    required this.eventType,
    this.attendanceStatus,
    this.timeRange,
    this.onTap,
    super.key,
  });

  final String eventTitle;
  final EventType eventType;
  final AttendanceStatus? attendanceStatus;
  final String? timeRange;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final mutedStyle = theme.textTheme.small.copyWith(
      color: theme.colorScheme.mutedForeground,
      fontSize: 11,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line 1: title
            Text(
              eventTitle,
              style: theme.textTheme.p.copyWith(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Line 2: time range (right-aligned)
            if (timeRange != null) ...[
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerRight,
                child: Text(timeRange!, style: mutedStyle),
              ),
            ],
            // Line 3: badge code + status message (right-aligned)
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.centerRight,
              child: Text.rich(
                TextSpan(
                  children: [
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: theme.colorScheme.mutedForeground,
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          _badgeCode(attendanceStatus),
                          style: mutedStyle.copyWith(
                            fontSize: mutedStyle.fontSize! + 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    TextSpan(
                      text: _statusMessage(attendanceStatus, eventType),
                      style: mutedStyle.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _badgeCode(AttendanceStatus? status) {
    if (status == null) return '?';
    return switch (status) {
      AttendanceStatus.present => 'P',
      AttendanceStatus.absent => 'A',
      AttendanceStatus.late => 'L',
      AttendanceStatus.onLeave => 'OL',
      AttendanceStatus.onLeaveRequested => 'LR',
    };
  }

  static String _eventTypeName(EventType type) {
    return switch (type) {
      EventType.programme => 'programme',
      EventType.camp => 'camp',
      EventType.oneOff => 'event',
    };
  }

  static String _statusMessage(AttendanceStatus? status, EventType eventType) {
    final typeName = _eventTypeName(eventType);
    if (status == null) return 'Not recorded';
    return switch (status) {
      AttendanceStatus.present => 'You were present for this $typeName',
      AttendanceStatus.absent => 'You missed this $typeName',
      AttendanceStatus.late => 'You were late for this $typeName',
      AttendanceStatus.onLeaveRequested =>
        'You have sent a leave request for this $typeName',
      AttendanceStatus.onLeave =>
        "You were on leave and didn't attend this $typeName",
    };
  }
}
