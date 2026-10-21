import 'package:cl_member_auth/cl_member_auth.dart' show canManageEvent;
import 'package:club_sdk_2/club_sdk_2.dart';

import '../models/admin_occurrence_action.dart';
import 'one_off_time_rules.dart';

/// The actions the occurrence card offers [actingUser] on [occurrence] of
/// [event], in display order, as the server accepts them:
///
/// | Occurrence | Before `start − 30min` | From `start − 30min` |
/// |---|---|---|
/// | scheduled / rescheduled | [scheduledActionsFor] the event's type, and Manage requests | Attendance, until `end + 15d` (a super-admin: no end) |
/// | cancelled | Undo Cancel | Undo Cancel, a super-admin only |
/// | cancelled one-off | Reinstate | Reinstate until the start, then none |
/// | live one-off, for a super-admin | as above | Attendance, and Call off |
/// | completed | none | Attendance, as above |
///
/// Attendance is offered to the event's staff (`canManageAttendance`); every
/// other action to its organizer or an admin only (`canManageEvent`), as the
/// server requires (club_core#146). From 30 minutes before the start the
/// server restores a cancelled occurrence for a super-admin only, and never
/// record attendance on one (club_client#177).
///
/// A one-off is called off and reinstated through its own verbs (`drop`,
/// `reinstate`), never the per-occurrence cancel and undo-cancel, which the
/// server refuses for it (club_server#48). A called-off one-off offers
/// Reinstate until its start and nothing after it, for a super-admin too
/// (one-off R7, [canReinstateOneOffAt]; club_client#183). A super-admin
/// may call a live one-off off after the 30-minute mark and after its
/// start too (R5a, [canCallOffOneOffAt]), as on its event page
/// (club_client#187).
///
/// A slot at or after the event's cutoff (`untilTimeUtc`) was cancelled with
/// the series: it comes back only when the series cancel is undone, so it
/// offers nothing.
List<AdminOccurrenceAction> adminOccurrenceActionsFor({
  required Occurrence occurrence,
  required Event event,
  required UserPrivate actingUser,
}) {
  final start = occurrence.actualStartTimeUtc;
  final inSchedulingWindow = isInScheduleManagementWindow(start);

  if (occurrence.status == OccurrenceStatus.cancelled) {
    if (isCutOffBySeries(event, occurrence)) return const [];
    if (!canManageEvent(event, actingUser)) return const [];
    if (event.type == EventType.oneOff) {
      return canReinstateOneOffAt(occurrence.originalStartTimeUtc)
          ? const [AdminOccurrenceAction.reinstate]
          : const [];
    }
    if (inSchedulingWindow || actingUser.isSuperAdmin) {
      return const [AdminOccurrenceAction.undoCancel];
    }
    return const [];
  }

  final inAttendanceWindow = canMarkAttendanceNow(
    actingUser: actingUser,
    effectiveStartTimeUtc: start,
    effectiveEndTimeUtc: occurrence.actualEndTimeUtc,
  );
  if (inAttendanceWindow) {
    return [
      if (canManageAttendance(event, actingUser))
        AdminOccurrenceAction.attendance,
      if (event.type == EventType.oneOff &&
          occurrence.status != OccurrenceStatus.cancelled &&
          canManageEvent(event, actingUser) &&
          canCallOffOneOffAt(start, actingUser))
        AdminOccurrenceAction.callOff,
    ];
  }

  // Past the edit window, the server rejects further mutations; the
  // remaining actions are the organizer's or an admin's (club_core#146).
  if (!inSchedulingWindow || !canManageEvent(event, actingUser)) {
    return const [];
  }

  // A rescheduled occurrence is still a live, future day: it offers the
  // same actions as a scheduled one, all keyed by `originalStartTimeUtc`.
  final live =
      occurrence.status == OccurrenceStatus.scheduled ||
      occurrence.status == OccurrenceStatus.rescheduled;
  return live
      ? [
          ...scheduledActionsFor(event.type),
          AdminOccurrenceAction.manageRequests,
        ]
      : const [];
}

/// Whether [occurrence] is at or after [event]'s cutoff, so cancelled with
/// the series (a cancelled camp, a terminated programme) rather than alone.
bool isCutOffBySeries(Event event, Occurrence occurrence) {
  final cutoff = event.untilTimeUtc;
  return cutoff != null && !occurrence.originalStartTimeUtc.isBefore(cutoff);
}

/// The actions on a live, future occurrence that change its schedule, as
/// the server offers them for [type] (club_client#178):
///
/// - a camp: Reschedule, Cancel this occurrence, Cancel entire series;
/// - a programme: Reschedule, Cancel this occurrence, End programme from
///   here (a programme is terminated, never cancelled as a series);
/// - a one-off: Call off. Its one occurrence is moved with the event's own
///   reschedule, on its event page.
List<AdminOccurrenceAction> scheduledActionsFor(EventType type) =>
    switch (type) {
      EventType.camp => const [
        AdminOccurrenceAction.reschedule,
        AdminOccurrenceAction.cancelOccurrence,
        AdminOccurrenceAction.cancelSeries,
      ],
      EventType.programme => const [
        AdminOccurrenceAction.reschedule,
        AdminOccurrenceAction.cancelOccurrence,
        AdminOccurrenceAction.endProgramme,
      ],
      EventType.oneOff => const [AdminOccurrenceAction.callOff],
    };
