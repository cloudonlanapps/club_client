import 'package:cl_club_events/src/models/occurrence_reschedule_form_helpers.dart';
import 'package:cl_club_forms/cl_club_forms.dart'
    show OccurrenceRescheduleFormFields, OneOffScheduleData;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadTimeOfDay;

Occurrence _occurrence({
  required DateTime actualStartTimeUtc,
  required DateTime actualEndTimeUtc,
  int venueId = 7,
  int eventId = 42,
  DateTime? originalStartTimeUtc,
  int version = 1,
}) {
  return Occurrence(
    version: version,
    eventId: eventId,
    originalStartTimeUtc: originalStartTimeUtc ?? actualStartTimeUtc,
    actualStartTimeUtc: actualStartTimeUtc,
    actualEndTimeUtc: actualEndTimeUtc,
    status: OccurrenceStatus.scheduled,
    venueId: venueId,
  );
}

/// Records the single `rescheduleOccurrence` call the adapter makes, without
/// touching the network. Overriding the one method is enough — the adapter
/// never reads `ref`.
class _FakeCampNotifier extends ClEventsMasterNotifier {
  int? eventId;
  DateTime? occurrenceTimeUtc;
  DateTime? newStartTimeUtc;
  int? newDurationMinutes;
  int? newVenueId;
  int? version;
  int calls = 0;

  @override
  Future<void> rescheduleOccurrence(
    int eventId,
    DateTime occurrenceTimeUtc, {
    required int version,
    DateTime? newStartTimeUtc,
    int? newDurationMinutes,
    int? newVenueId,
  }) async {
    calls++;
    this.eventId = eventId;
    this.occurrenceTimeUtc = occurrenceTimeUtc;
    this.newStartTimeUtc = newStartTimeUtc;
    this.newDurationMinutes = newDurationMinutes;
    this.newVenueId = newVenueId;
    this.version = version;
  }
}

void main() {
  // A camp day: starts 2026-07-01 06:00 local, runs 90 minutes, venue 7.
  final start = DateTime(2026, 7, 1, 6).toUtc();
  final end = DateTime(2026, 7, 1, 7, 30).toUtc();

  group('buildOccurrenceRescheduleInitialValues', () {
    test('Issue 750: seeds date, start time, duration and venue from the '
        'occurrence', () {
      final values = buildOccurrenceRescheduleInitialValues(
        _occurrence(actualStartTimeUtc: start, actualEndTimeUtc: end),
      );

      final schedule =
          values[OccurrenceRescheduleFormFields.scheduleId]
              as OneOffScheduleData;
      final startLocal = start.toLocal();
      expect(
        schedule.date,
        DateTime(startLocal.year, startLocal.month, startLocal.day),
      );
      expect(
        schedule.startTime,
        ShadTimeOfDay(
          hour: startLocal.hour,
          minute: startLocal.minute,
          second: 0,
        ),
      );
      expect(schedule.durationMinutes, 90);
      expect(values[OccurrenceRescheduleFormFields.venueId], 7);
    });
  });

  group('OccurrenceRescheduleFormSubmit.updateSchedule', () {
    test('Issue 750: an unchanged round-trip issues no SDK call', () async {
      final occurrence = _occurrence(
        actualStartTimeUtc: start,
        actualEndTimeUtc: end,
      );
      final notifier = _FakeCampNotifier();

      await OccurrenceRescheduleFormSubmit.updateSchedule(
        occurrence: occurrence,
        values: buildOccurrenceRescheduleInitialValues(occurrence),
        notifier: notifier,
      );

      expect(notifier.calls, 0);
    });

    test('Issue 750: changing only the venue sends just newVenueId, keyed by '
        'the original start', () async {
      final occurrence = _occurrence(
        actualStartTimeUtc: start,
        actualEndTimeUtc: end,
        originalStartTimeUtc: start,
      );
      final notifier = _FakeCampNotifier();
      final values = buildOccurrenceRescheduleInitialValues(occurrence)
        ..[OccurrenceRescheduleFormFields.venueId] = 9;

      await OccurrenceRescheduleFormSubmit.updateSchedule(
        occurrence: occurrence,
        values: values,
        notifier: notifier,
      );

      expect(notifier.calls, 1);
      expect(notifier.eventId, 42);
      expect(notifier.occurrenceTimeUtc, start);
      expect(notifier.newVenueId, 9);
      expect(notifier.newStartTimeUtc, isNull);
      expect(notifier.newDurationMinutes, isNull);
    });

    test(
      'Issue 750: moving to another day sends newStartTimeUtc only',
      () async {
        final occurrence = _occurrence(
          actualStartTimeUtc: start,
          actualEndTimeUtc: end,
        );
        final notifier = _FakeCampNotifier();
        final schedule =
            buildOccurrenceRescheduleInitialValues(
                  occurrence,
                )[OccurrenceRescheduleFormFields.scheduleId]
                as OneOffScheduleData;
        // Same time of day, three days later.
        final values = buildOccurrenceRescheduleInitialValues(occurrence)
          ..[OccurrenceRescheduleFormFields.scheduleId] = OneOffScheduleData(
            date: DateTime(2026, 7, 4),
            startTime: schedule.startTime,
            durationMinutes: schedule.durationMinutes,
          );

        await OccurrenceRescheduleFormSubmit.updateSchedule(
          occurrence: occurrence,
          values: values,
          notifier: notifier,
        );

        expect(notifier.calls, 1);
        expect(notifier.newStartTimeUtc, DateTime(2026, 7, 4, 6).toUtc());
        expect(notifier.newDurationMinutes, isNull);
        expect(notifier.newVenueId, isNull);
      },
    );

    test(
      'Issue 750: changing only the duration sends just newDurationMinutes',
      () async {
        final occurrence = _occurrence(
          actualStartTimeUtc: start,
          actualEndTimeUtc: end,
        );
        final notifier = _FakeCampNotifier();
        final schedule =
            buildOccurrenceRescheduleInitialValues(
                  occurrence,
                )[OccurrenceRescheduleFormFields.scheduleId]
                as OneOffScheduleData;
        final values = buildOccurrenceRescheduleInitialValues(occurrence)
          ..[OccurrenceRescheduleFormFields.scheduleId] = OneOffScheduleData(
            date: schedule.date,
            startTime: schedule.startTime,
            durationMinutes: 120,
          );

        await OccurrenceRescheduleFormSubmit.updateSchedule(
          occurrence: occurrence,
          values: values,
          notifier: notifier,
        );

        expect(notifier.calls, 1);
        expect(notifier.newDurationMinutes, 120);
        expect(notifier.newStartTimeUtc, isNull);
        expect(notifier.newVenueId, isNull);
      },
    );
  });

  test('Issue 69: updateSchedule sends the occurrence version it was '
      'loaded with', () async {
    final occurrence = _occurrence(
      actualStartTimeUtc: start,
      actualEndTimeUtc: end,
      version: 3,
    );
    final notifier = _FakeCampNotifier();
    final values = buildOccurrenceRescheduleInitialValues(occurrence)
      ..[OccurrenceRescheduleFormFields.venueId] = 9;

    await OccurrenceRescheduleFormSubmit.updateSchedule(
      occurrence: occurrence,
      values: values,
      notifier: notifier,
    );

    expect(notifier.version, 3);
  });

  group('occurrenceRescheduleErrorMessage', () {
    test('Issue 750: maps each reschedule guard to a friendly message', () {
      String msg(String code) => occurrenceRescheduleErrorMessage(
        ServerException(statusCode: 422, message: 'raw', code: code),
      );

      expect(msg('PAST_RESCHEDULE_TIME'), contains('must be in the future'));
      expect(msg('RESCHEDULE_LEAD_TIME_VIOLATED'), contains('too close'));
      expect(msg('VENUE_NOT_FOUND'), contains('no longer available'));
      expect(msg('CANCELLED_OCCURRENCE'), contains('cancelled'));
      expect(msg('NOTHING_TO_RESCHEDULE'), contains('before saving'));
    });

    test('Issue 750: falls back to the server message for other codes', () {
      expect(
        occurrenceRescheduleErrorMessage(
          const ServerException(
            statusCode: 400,
            message: 'Something else',
            code: 'WHATEVER',
          ),
        ),
        'Something else',
      );
    });
  });

  test('Issue 69: a stale version names who changed the session', () {
    final message = occurrenceRescheduleErrorMessage(
      StaleVersionException(
        message: 'raw',
        version: 5,
        updatedAtUtc: DateTime.utc(2026, 9, 1, 10),
        updatedBy: 'coach_a',
      ),
    );

    expect(message, startsWith('This session was changed by coach_a'));
  });
}
