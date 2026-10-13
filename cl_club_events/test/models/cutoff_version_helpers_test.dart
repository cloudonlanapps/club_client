import 'package:cl_club_events/src/models/event_cancellation_form_helpers.dart';
import 'package:cl_club_events/src/models/programme_schedule_form_helpers.dart';
import 'package:cl_club_events/src/providers/event_notifier.dart';
import 'package:cl_club_forms/cl_club_forms.dart'
    show EventCancellationFormFields;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/programme_fixtures.dart';
import '../support/recording_cutoff_events.dart';

/// The local calendar day [days] from today.
DateTime _day(int days) {
  final t = localNoon(days);
  return DateTime(t.year, t.month, t.day);
}

void main() {
  group('Issue 123: the end-date adapter sends the version of the programme '
      'it was given', () {
    test(
      'Issue 123: setting an end date terminates with the version',
      () async {
        final event = programmeFixture();
        final notifier = RecordingCutoffEvents(event);

        await ProgrammeScheduleFormSubmit.adjustEndDate(
          event: event,
          lastDay: _day(5),
          reason: 'Season over',
          notifier: notifier,
        );

        expect(notifier.calls, ['terminate(v${event.version})']);
      },
    );

    test('Issue 123: moving an end date extends with the version', () async {
      final event = programmeFixture(untilTimeUtc: localNoon(6).toUtc());
      final notifier = RecordingCutoffEvents(event);

      await ProgrammeScheduleFormSubmit.adjustEndDate(
        event: event,
        lastDay: _day(9),
        reason: '',
        notifier: notifier,
      );

      expect(notifier.calls, ['extend(v${event.version})']);
    });

    test('Issue 123: clearing an end date extends indefinitely with the '
        'version', () async {
      final event = programmeFixture(untilTimeUtc: localNoon(6).toUtc());
      final notifier = RecordingCutoffEvents(event);

      await ProgrammeScheduleFormSubmit.adjustEndDate(
        event: event,
        lastDay: null,
        reason: '',
        notifier: notifier,
      );

      expect(notifier.calls, ['extendIndefinitely(v${event.version})']);
    });

    test('Issue 123: a stale version reaches the caller as it is', () async {
      final event = programmeFixture();
      final notifier = RecordingCutoffEvents(event)..error = staleCutoff();

      await expectLater(
        ProgrammeScheduleFormSubmit.adjustEndDate(
          event: event,
          lastDay: _day(5),
          reason: 'Season over',
          notifier: notifier,
        ),
        throwsA(isA<StaleVersionException>()),
      );
    });
  });

  test('Issue 123: the cancellation adapter cancels a camp with the version '
      'it was given', () async {
    final event = programmeFixture();
    final notifier = RecordingCutoffEvents(event);

    await EventCancellationFormSubmit.cancelCamp(
      eventId: event.id,
      eventVersion: 7,
      values: {
        EventCancellationFormFields.reasonId: 'Rink closed',
        EventCancellationFormFields.fromSessionId: localNoon(3).toUtc(),
      },
      notifier: notifier,
    );

    expect(notifier.calls, ['cancelSeries(v7)']);
  });

  test('Issue 123: the event notifier cancels with the version of the event '
      'it holds', () async {
    final event = programmeFixture();
    final events = RecordingCutoffEvents(event);
    final container = ProviderContainer(
      overrides: [clEventsMasterProvider.overrideWith(() => events)],
    );
    addTearDown(container.dispose);
    await container.read(eventNotifierProvider(event.id).future);

    await container
        .read(eventNotifierProvider(event.id).notifier)
        .cancelEvent(
          reason: 'Rink closed',
          effectiveDateTimeUtc: localNoon(3).toUtc(),
        );

    expect(events.calls, ['cancelSeries(v${event.version})']);
  });
}
