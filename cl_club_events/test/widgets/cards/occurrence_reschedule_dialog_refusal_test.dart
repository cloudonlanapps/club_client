// Issue 97: the Reschedule Session dialog shows a refused move on the field
// it is about or inline, and a failure that is not about the move in a
// toast.
import 'dart:async';

import 'package:cl_club_events/src/widgets/cards/actions/occurrence_reschedule_dialog.dart';
import 'package:cl_club_forms/cl_club_forms.dart'
    show
        OccurrenceRescheduleForm,
        OccurrenceRescheduleFormFields,
        OccurrenceRescheduleFormState,
        OneOffScheduleData;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier, clEventsMasterProvider, clVenuesProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

final DateTime _start = DateTime.now().toUtc().add(const Duration(days: 3));

final Occurrence _occurrence = Occurrence(
  eventId: 1,
  originalStartTimeUtc: _start,
  actualStartTimeUtc: _start,
  actualEndTimeUtc: _start.add(const Duration(hours: 1)),
  status: OccurrenceStatus.scheduled,
  venueId: 7,
  version: 2,
);

/// Fails every reschedule with [failure].
class _FailingEvents extends ClEventsMasterNotifier {
  _FailingEvents(this.failure);

  final Exception failure;

  @override
  Future<Map<int, Event>> build() async => {};

  @override
  Future<void> rescheduleOccurrence(
    int eventId,
    DateTime occurrenceTimeUtc, {
    required int version,
    DateTime? newStartTimeUtc,
    int? newDurationMinutes,
    int? newVenueId,
  }) async => throw failure;
}

Finder _field(String id) =>
    find.byWidgetPredicate((w) => w is ShadFormBuilderField && w.id == id);

/// Opens the dialog, makes the session half an hour longer and saves, the
/// save failing with [failure].
Future<void> _saveFailing(WidgetTester tester, Exception failure) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clEventsMasterProvider.overrideWith(() => _FailingEvents(failure)),
        clVenuesProvider.overrideWith(
          (ref, key) async => [
            Venue(
              id: 7,
              name: 'Main rink',
              isDefault: true,
              createdAtUtc: DateTime.utc(2025),
              updatedAtUtc: DateTime.utc(2025),
            ),
          ],
        ),
      ],
      child: ShadApp(
        home: Scaffold(
          body: OccurrenceRescheduleDialog(occurrence: _occurrence),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final form = tester
      .state<OccurrenceRescheduleFormState>(
        find.byType(OccurrenceRescheduleForm),
      )
      .formKey
      .currentState!;
  final schedule =
      form.value[OccurrenceRescheduleFormFields.scheduleId]
          as OneOffScheduleData;
  form.setFieldValue<OneOffScheduleData>(
    OccurrenceRescheduleFormFields.scheduleId,
    OneOffScheduleData(
      date: schedule.date,
      startTime: schedule.startTime,
      durationMinutes: 90,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ShadButton, 'Save'));
  await tester.pumpAndSettle();
}

ServerException _refused(String code, {int status = 422}) => ServerException(
  statusCode: status,
  code: code,
  message: 'raw server text',
);

void _expectDialogOn(WidgetTester tester) {
  expect(find.byType(OccurrenceRescheduleDialog), findsOneWidget);
  expect(
    tester
        .widget<OccurrenceRescheduleForm>(find.byType(OccurrenceRescheduleForm))
        .enabled,
    isTrue,
  );
  expect(
    tester
        .widget<ShadButton>(find.widgetWithText(ShadButton, 'Save'))
        .onPressed,
    isNotNull,
  );
}

void main() {
  group('Issue 97: Reschedule Session shows a refusal where it belongs', () {
    testWidgets('Issue 97: a move to an earlier time shows on the schedule, '
        'with no toast', (tester) async {
      await _saveFailing(tester, _refused(SdkErrorCode.postponeOnly));

      expect(
        find.descendant(
          of: _field(OccurrenceRescheduleFormFields.scheduleId),
          matching: find.textContaining('only be moved to a later time'),
        ),
        findsOneWidget,
      );
      expect(find.byType(ShadToast), findsNothing);
      expect(find.textContaining('raw server text'), findsNothing);
      _expectDialogOn(tester);
    });

    testWidgets('Issue 97: a venue that is gone shows on the venue', (
      tester,
    ) async {
      await _saveFailing(
        tester,
        _refused(SdkErrorCode.venueNotFound, status: 404),
      );

      expect(
        find.descendant(
          of: _field(OccurrenceRescheduleFormFields.venueId),
          matching: find.text('The selected venue is no longer available.'),
        ),
        findsOneWidget,
      );
      expect(find.byType(ShadToast), findsNothing);
    });

    testWidgets('Issue 97: a session too close to its start shows inline in '
        'the form', (tester) async {
      await _saveFailing(
        tester,
        _refused(SdkErrorCode.rescheduleLeadTimeViolated, status: 400),
      );

      expect(
        find.descendant(
          of: find.byType(OccurrenceRescheduleForm),
          matching: find.textContaining('too close to start'),
        ),
        findsOneWidget,
      );
      expect(find.byType(ShadToast), findsNothing);
      _expectDialogOn(tester);
    });

    testWidgets('Issue 97: a server that cannot be reached is a toast, not '
        'a message in the form, and the dialog is on again', (tester) async {
      await _saveFailing(tester, TimeoutException('connection closed'));

      expect(find.byType(ShadToast), findsOneWidget);
      expect(find.textContaining('connection closed'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(OccurrenceRescheduleForm),
          matching: find.byWidgetPredicate(
            (w) => w is Text && (w.data ?? '').contains('server'),
          ),
        ),
        findsNothing,
      );
      _expectDialogOn(tester);
    });

    testWidgets('Issue 97: a refusal the dialog has no words for is a toast '
        'with fixed text, never the raw message', (tester) async {
      await _saveFailing(tester, _refused('SOMETHING_NEW', status: 400));

      expect(find.byType(ShadToast), findsOneWidget);
      expect(find.textContaining('raw server text'), findsNothing);
      _expectDialogOn(tester);
    });
  });
}
