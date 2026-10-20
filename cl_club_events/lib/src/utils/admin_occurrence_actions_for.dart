import 'package:cl_member_auth/cl_member_auth.dart' show canManageEvent;
import 'package:club_sdk_2/club_sdk_2.dart';

import '../models/admin_occurrence_action.dart';

/// The actions the occurrence card offers [actingUser] on [occurrence] of
/// [event], in display order, as the server accepts them:
///
/// | Occurrence | Before `start − 30min` | From `start − 30min` |
/// |---|---|---|
/// | scheduled / rescheduled | [scheduledActionsFor] the event's type, and Manage requests | Attendance, until `end + 15d` (a super-admin: no end) |
/// | cancelled | Undo Cancel | Undo Cancel, a super-admin only |
/// | completed | none | Attendance, as above |
///
/// Attendance is offered to the event's staff (`canManageAttendance`); every
/// other action to its organizer or an admin only (`canManageEvent`), as the
/// server requires (club_core#146). From 30 minutes before the start the
/// server restores a cancelled occurrence for a super-admin only, and never
/// records attendance on one (club_client#177).
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
    return canManageAttendance(event, actingUser)
        ? const [AdminOccurrenceAction.attendance]
        : const [];
  }

  // Past the edit window, the server rejects further mutations; the
  // remaining actions are the organizer's or an admin's (club_core#146).
  if (!inSchedulingWindow || !canManageEvent(event, actingUser)) {
    return const [];
  }

  switch (occurrence.status) {
    // A rescheduled occurrence is still a live, future day: it offers the
    // same actions as a scheduled one, all keyed by `originalStartTimeUtc`.
    case OccurrenceStatus.scheduled || OccurrenceStatus.rescheduled:
      return [
        ...scheduledActionsFor(event.type),
        AdminOccurrenceAction.manageRequests,
      ];
    case OccurrenceStatus.cancelled || OccurrenceStatus.completed:
      return const [];
  }
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
