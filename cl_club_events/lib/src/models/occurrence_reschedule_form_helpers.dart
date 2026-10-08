import 'package:cl_club_forms/cl_club_forms.dart'
    show OccurrenceRescheduleFormFields, OneOffScheduleData;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;

import 'stale_version_message.dart';

/// SDK ↔ `OccurrenceRescheduleForm` adapter for a single camp occurrence.
///
/// The form is SDK-free in `ui_lib`; this helper owns the translation both
/// ways: [buildOccurrenceRescheduleInitialValues] (occurrence → form) and
/// [OccurrenceRescheduleFormSubmit.updateSchedule] (form → SDK). Mirrors
/// `camp_schedule_form_helpers.dart`, which owns the *series* reschedule.

/// Seeds `OccurrenceRescheduleForm` from an existing [occurrence]. The schedule
/// trio is read from the occurrence's *actual* (possibly already-overridden)
/// start / end so opening the editor round-trips to the same value — `isDirty`
/// stays false and an unmodified Save is a no-op.
Map<String, dynamic> buildOccurrenceRescheduleInitialValues(
  Occurrence occurrence,
) {
  final startLocal = occurrence.actualStartTimeUtc.toLocal();
  return {
    OccurrenceRescheduleFormFields.scheduleId: OneOffScheduleData(
      date: DateTime(startLocal.year, startLocal.month, startLocal.day),
      startTime: ShadTimeOfDay(
        hour: startLocal.hour,
        minute: startLocal.minute,
        second: 0,
      ),
      durationMinutes: occurrence.actualEndTimeUtc
          .difference(occurrence.actualStartTimeUtc)
          .inMinutes,
    ),
    OccurrenceRescheduleFormFields.venueId: occurrence.venueId,
  };
}

/// Maps a server reschedule-guard [ServerException] to a friendly,
/// admin-facing message. Falls back to the server's own message for codes the
/// reschedule flow doesn't special-case.
String occurrenceRescheduleErrorMessage(ServerException e) =>
    occurrenceRescheduleRefusal(e)?.message ?? e.message;

/// What the reschedule form shows for a save the server refused with [e]:
/// a fixed message, and the id of the form's field it is about (`null` when
/// it is about none of them and shows inline). `null` when the flow has no
/// words for the refusal; the host then reports a failed save in a toast.
({String message, String? fieldId})? occurrenceRescheduleRefusal(
  ServerException e,
) {
  if (e is StaleVersionException) {
    return (
      message: staleVersionMessage(e, subject: 'This session'),
      fieldId: null,
    );
  }
  const schedule = OccurrenceRescheduleFormFields.scheduleId;
  return switch (e.code) {
    'PAST_RESCHEDULE_TIME' => (
      message: 'The new start time must be in the future.',
      fieldId: schedule,
    ),
    SdkErrorCode.postponeOnly => (
      message:
          'A session can only be moved to a later time, not an earlier '
          'one.',
      fieldId: schedule,
    ),
    SdkErrorCode.invalidSessions => (
      message: 'This session has a timetable, so its duration cannot change.',
      fieldId: schedule,
    ),
    SdkErrorCode.venueNotFound => (
      message: 'The selected venue is no longer available.',
      fieldId: OccurrenceRescheduleFormFields.venueId,
    ),
    SdkErrorCode.rescheduleLeadTimeViolated => (
      message:
          'This session is too close to start — it can no longer be '
          'rescheduled.',
      fieldId: null,
    ),
    SdkErrorCode.pastOccurrence => (
      message: 'This session has already started and cannot be rescheduled.',
      fieldId: null,
    ),
    SdkErrorCode.cancelledOccurrence => (
      message: 'This session is cancelled and cannot be rescheduled.',
      fieldId: null,
    ),
    SdkErrorCode.nothingToReschedule => (
      message: 'Change the date, time, duration, or venue before saving.',
      fieldId: null,
    ),
    _ => null,
  };
}

/// Bridges `OccurrenceRescheduleForm` to the SDK occurrence-reschedule call.
class OccurrenceRescheduleFormSubmit {
  const OccurrenceRescheduleFormSubmit._();

  /// Applies the edited [values] to [occurrence] via the master [notifier],
  /// sending **only** the fields the admin changed (a `null` argument is "no
  /// change" to the server). The occurrence is keyed by its *original* start
  /// time — the stable override key — matching the cancel / undo paths — and
  /// carries the occurrence's `version` as loaded (#69).
  ///
  /// Throws on the server guards (`PAST_RESCHEDULE_TIME`,
  /// `RESCHEDULE_LEAD_TIME_VIOLATED`, `VENUE_NOT_FOUND`,
  /// `CANCELLED_OCCURRENCE`, `NOTHING_TO_RESCHEDULE`) and on a stale version
  /// (`StaleVersionException`); the caller surfaces a friendly message.
  static Future<void> updateSchedule({
    required Occurrence occurrence,
    required Map<String, dynamic> values,
    required ClEventsMasterNotifier notifier,
  }) async {
    final schedule =
        values[OccurrenceRescheduleFormFields.scheduleId] as OneOffScheduleData;
    final venueId = values[OccurrenceRescheduleFormFields.venueId] as int;

    final date = schedule.date!;
    final time = schedule.startTime!;
    final newStartUtc = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    ).toUtc();
    final originalDuration = occurrence.actualEndTimeUtc
        .difference(occurrence.actualStartTimeUtc)
        .inMinutes;

    final startChanged = newStartUtc != occurrence.actualStartTimeUtc;
    final durationChanged = schedule.durationMinutes != originalDuration;
    final venueChanged = venueId != occurrence.venueId;

    if (!startChanged && !durationChanged && !venueChanged) {
      // Defensive: `isDirty` already prevents an unmodified Save from getting
      // here, but never issue a no-op reschedule.
      return;
    }

    await notifier.rescheduleOccurrence(
      occurrence.eventId,
      occurrence.originalStartTimeUtc,
      version: occurrence.version,
      newStartTimeUtc: startChanged ? newStartUtc : null,
      newDurationMinutes: durationChanged ? schedule.durationMinutes : null,
      newVenueId: venueChanged ? venueId : null,
    );
  }
}
