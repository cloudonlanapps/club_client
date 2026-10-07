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
String occurrenceRescheduleErrorMessage(ServerException e) {
  if (e is StaleVersionException) {
    return staleVersionMessage(e, subject: 'This session');
  }
  switch (e.code) {
    case 'PAST_RESCHEDULE_TIME':
      return 'The new start time must be in the future.';
    case 'RESCHEDULE_LEAD_TIME_VIOLATED':
      return 'This session is too close to start — it can no longer be '
          'rescheduled.';
    case 'VENUE_NOT_FOUND':
      return 'The selected venue is no longer available.';
    case 'CANCELLED_OCCURRENCE':
      return 'This session is cancelled and cannot be rescheduled.';
    case 'NOTHING_TO_RESCHEDULE':
      return 'Change the date, time, duration, or venue before saving.';
    default:
      return e.message;
  }
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
