import 'package:cl_club_venues/cl_club_venues.dart' show EventVenueLine;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

import 'actions/admin_occurrence_actions.dart';
import 'actions/user_occurrence_actions.dart';
import 'attendance_badge.dart';

/// List-row card for a single occurrence.
///
/// Caller passes only the keys — `(eventId, occurrenceTime, range)` —
/// plus an optional [username] and navigation callbacks. The card
/// resolves the [Occurrence] itself from the appropriate range-keyed
/// provider, derives its own caption, and mounts the right action
/// resolver internally.
///
/// Data sourcing rule:
///   * `username == null` → admin lens. Occurrence from
///     `clOccurrencesProvider((from: range.from, to: range.to))`.
///     Trailing = [AdminOccurrenceActions].
///   * `username != null` → user lens. Occurrence from
///     `clMyOccurrencesListProvider((username, range))`. Trailing =
///     [UserOccurrenceActions] (or [AttendanceBadge] when past with
///     recorded attendance).
class OccurrenceCard extends ConsumerWidget {
  const OccurrenceCard({
    required this.eventId,
    required this.occurrenceTime,
    required this.range,
    this.username,
    this.onTap,
    this.onMarkAttendance,
    this.showRecurrence = false,
    this.showVenue = false,
    this.dense = false,
    this.muteTerminal = true,
    super.key,
  });

  final int eventId;

  /// The occurrence's original (RRULE-derived) start time. Used together
  /// with [eventId] to identify the row inside the range fetch.
  final DateTime occurrenceTime;

  /// Date range the host is currently viewing. The card uses this to
  /// resolve the occurrence from the range-keyed provider.
  final ({DateTime from, DateTime to}) range;

  /// Target user whose perspective this row represents. `null` → admin.
  final String? username;

  final VoidCallback? onTap;

  /// Admin perspective only — navigation callback when the user picks
  /// "Attendance" (during the attendance edit window).
  final void Function(int eventId, DateTime occurrenceTimeUtc)?
  onMarkAttendance;

  /// Render the event's recurrence summary under the schedule line.
  /// Used by dashboard discovery surfaces (Today's Events, Public Events).
  final bool showRecurrence;

  /// Render the venue line under the schedule.
  final bool showVenue;

  /// Compact padding + 13px title — used by calendar surfaces.
  final bool dense;

  /// Dim past / cancelled / completed rows. Dashboard panels mute;
  /// calendar surfaces don't (the grid conveys terminal status).
  final bool muteTerminal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final occurrence = _resolveOccurrence(ref);
    if (occurrence == null) {
      return EntityCard(
        image: EntityImage.placeholder(),
        title: 'Event #$eventId',
        onTap: onTap,
        dense: dense,
      );
    }

    final event = _resolveEvent(ref);
    final title = event?.title ?? 'Event #$eventId';

    final now = DateTime.now().toUtc();
    final isPast = occurrence.actualEndTimeUtc.isBefore(now);
    final isTerminal =
        occurrence.status == OccurrenceStatus.cancelled ||
        occurrence.status == OccurrenceStatus.completed;

    final caption = _captionFor(ref, occurrence);
    final muted = muteTerminal && (isPast || isTerminal);
    EntityCard card({
      Widget? trailingAction,
      List<ActionItem>? trailingActions,
    }) => EntityCard(
      image: EntityImage.placeholder(),
      title: title,
      caption: caption,
      body: OccurrenceBody(
        occurrence: occurrence,
        event: event,
        showRecurrence: showRecurrence,
        showVenue: showVenue,
      ),
      trailingAction: trailingAction,
      trailingActions: trailingActions,
      onTap: onTap,
      dense: dense,
      muted: muted,
    );

    if (username == null) {
      if (onMarkAttendance == null) return card();
      return AdminOccurrenceActions(
        occurrence: occurrence,
        onMarkAttendance: onMarkAttendance!,
        builder: (context, actions) =>
            card(trailingActions: actions.isEmpty ? null : actions),
      );
    }

    // Past occurrence with a recorded outcome: show the read-only badge via
    // the bespoke widget slot instead of an action list.
    final attendance = occurrence.attendanceStatus;
    if (isPast && attendance != null) {
      return card(trailingAction: AttendanceBadge(status: attendance));
    }
    return UserOccurrenceActions(
      username: username!,
      occurrence: occurrence,
      builder: (context, actions) =>
          card(trailingActions: actions.isEmpty ? null : actions),
    );
  }

  Occurrence? _resolveOccurrence(WidgetRef ref) {
    final List<Occurrence>? list;
    if (username == null) {
      list = ref
          .watch(clOccurrencesProvider((from: range.from, to: range.to)))
          .valueOrNull;
    } else {
      list = ref
          .watch(
            clMyOccurrencesListProvider((
              username: username!,
              fromTimeUtc: range.from,
              toTimeUtc: range.to,
            )),
          )
          .valueOrNull;
    }
    return list
        ?.where(
          (o) =>
              o.eventId == eventId &&
              o.originalStartTimeUtc.isAtSameMomentAs(occurrenceTime),
        )
        .firstOrNull;
  }

  Event? _resolveEvent(WidgetRef ref) {
    if (username == null) {
      return ref.watch(clEventsMasterProvider).valueOrNull?[eventId];
    }
    final events = ref.watch(clMyEventsMasterProvider(username!)).valueOrNull;
    return events?.where((e) => e.id == eventId).firstOrNull;
  }

  String? _captionFor(WidgetRef ref, Occurrence occurrence) {
    if (occurrence.status == OccurrenceStatus.cancelled) return 'Cancelled';
    if (occurrence.status == OccurrenceStatus.completed) return 'Completed';

    if (username == null) return null;

    final attendance = occurrence.attendanceStatus;
    final now = DateTime.now().toUtc();
    final isPast = occurrence.actualEndTimeUtc.isBefore(now);
    if (isPast) return _pastCaption(attendance);

    final enrollment = ref
        .watch(
          clMyEnrollmentProvider(
            (username: username!, eventId: eventId),
          ),
        )
        .valueOrNull
        ?.status;
    return _futureCaption(attendance, enrollment);
  }

  /// Member-perspective caption for an upcoming occurrence. Mirrors the
  /// `myEventsFutureCaption` helper that previously lived in cl_member_zone.
  static String? _futureCaption(AttendanceStatus? a, EnrollmentStatus? e) {
    switch (a) {
      case AttendanceStatus.onLeaveRequested:
        return 'Leave requested';
      case AttendanceStatus.onLeave:
        return 'Leave approved';
      case AttendanceStatus.present:
      case AttendanceStatus.absent:
      case AttendanceStatus.late:
      case null:
        return _enrollmentCaption(e);
    }
  }

  /// Member-perspective caption for a past occurrence.
  static String _pastCaption(AttendanceStatus? a) {
    switch (a) {
      case AttendanceStatus.present:
        return 'You attended';
      case AttendanceStatus.absent:
        return 'You were absent';
      case AttendanceStatus.late:
        return 'You were late';
      case AttendanceStatus.onLeave:
        return 'You were on leave';
      case AttendanceStatus.onLeaveRequested:
        return 'Leave was pending';
      case null:
        return 'Attendance not recorded';
    }
  }

  static String? _enrollmentCaption(EnrollmentStatus? s) {
    switch (s) {
      case EnrollmentStatus.invited:
        return 'You are invited';
      case EnrollmentStatus.accepted:
        return 'You are accepted';
      case EnrollmentStatus.assigned:
        return 'You are assigned';
      case EnrollmentStatus.assignedTrial:
        return 'Trial — assigned';
      case EnrollmentStatus.requested:
        return 'Awaiting admin approval';
      case EnrollmentStatus.withdrawRequested:
        return 'Withdrawal pending';
      case EnrollmentStatus.rejected:
      case EnrollmentStatus.declined:
      case EnrollmentStatus.withdrawn:
      case EnrollmentStatus.removed:
      case null:
        return null;
    }
  }
}

class OccurrenceBody extends StatelessWidget {
  const OccurrenceBody({
    required this.occurrence,
    required this.event,
    required this.showRecurrence,
    required this.showVenue,
    super.key,
  });

  final Occurrence occurrence;
  final Event? event;
  final bool showRecurrence;
  final bool showVenue;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final fg = theme.colorScheme.mutedForeground;
    final detailStyle = theme.textTheme.small.copyWith(color: fg);

    final recurrence = showRecurrence && event != null
        ? eventScheduleSummary(event!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_scheduleLine(occurrence)),
        if (recurrence != null) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.repeat, size: 12, color: fg),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  recurrence,
                  style: detailStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
        if (showVenue) ...[
          const SizedBox(height: 2),
          EventVenueLine(venueId: occurrence.venueId),
        ],
      ],
    );
  }

  String _scheduleLine(Occurrence o) {
    final fmt = DateFormat('h:mm a');
    final start = fmt.format(o.actualStartTimeUtc.toLocal());
    final end = fmt.format(o.actualEndTimeUtc.toLocal());
    final base = '$start – $end';
    if (o.status == OccurrenceStatus.rescheduled &&
        !o.actualStartTimeUtc.isAtSameMomentAs(o.originalStartTimeUtc)) {
      return 'Rescheduled — $base';
    }
    return base;
  }
}
