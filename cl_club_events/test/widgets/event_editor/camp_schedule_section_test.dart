import 'package:cl_club_events/src/widgets/event_editor/camp_schedule_section.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show clOccurrencesProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show SectionEditButton;

Event _camp() => Event(
  id: 1,
  title: 'Summer Camp',
  description: '',
  type: EventType.camp,
  visibility: Visibility.public,
  venueId: 7,
  startTimeUtc: DateTime.utc(2026, 8, 2, 6),
  endTimeUtc: DateTime.utc(2026, 8, 2, 8),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
  rrule: 'FREQ=DAILY;COUNT=3',
);

Occurrence _occ({
  required DateTime original,
  OccurrenceStatus status = OccurrenceStatus.scheduled,
  bool isRescheduled = false,
}) => Occurrence(
  eventId: 1,
  originalStartTimeUtc: original,
  actualStartTimeUtc: original,
  actualEndTimeUtc: original.add(const Duration(hours: 2)),
  status: status,
  venueId: 7,
  isRescheduled: isRescheduled,
);

Future<void> _pump(
  WidgetTester tester, {
  required bool canEdit,
  String? lockReason,
  List<Occurrence> occurrences = const [],
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clOccurrencesProvider.overrideWith((ref, key) async => occurrences),
      ],
      child: ShadApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CampScheduleSection(
              event: _camp(),
              canEdit: canEdit,
              lockReason: lockReason,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Issue 705: shows the schedule and an edit pencil when allowed', (
    tester,
  ) async {
    await _pump(tester, canEdit: true);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.byType(SectionEditButton), findsOneWidget);
  });

  testWidgets('Issue 705: hides the pencil from a non-admin viewer', (
    tester,
  ) async {
    await _pump(tester, canEdit: false);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.byType(SectionEditButton), findsNothing);
  });

  testWidgets('Issue 705: locked camp shows the pencil + a lock hint, and '
      'tapping it toasts instead of editing', (tester) async {
    const reason =
        'This camp has already started, so its schedule can no '
        'longer be edited.';
    await _pump(tester, canEdit: true, lockReason: reason);

    // The pencil is offered and the muted lock hint explains the lock.
    expect(find.byType(SectionEditButton), findsOneWidget);
    expect(find.text(reason), findsOneWidget);

    await tester.tap(find.byType(SectionEditButton));
    await tester.pumpAndSettle();

    // No editor; a toast surfaced the reason (hint + toast → 2 instances).
    expect(find.text('Save'), findsNothing);
    expect(find.text(reason), findsNWidgets(2));
  });

  testWidgets('Issue 705: no overrides → pencil opens the editor directly', (
    tester,
  ) async {
    await _pump(
      tester,
      canEdit: true,
      occurrences: [_occ(original: DateTime.utc(2026, 8, 2, 6))],
    );

    await tester.tap(find.byType(SectionEditButton));
    await tester.pumpAndSettle();

    // No confirmation; the editor (with its Save action) is shown.
    expect(find.text('This series has individual day edits'), findsNothing);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('Issue 705: overrides → pencil confirms before editing', (
    tester,
  ) async {
    await _pump(
      tester,
      canEdit: true,
      occurrences: [
        _occ(original: DateTime.utc(2026, 8, 2, 6)),
        _occ(
          original: DateTime.utc(2026, 8, 3, 6),
          status: OccurrenceStatus.cancelled,
          isRescheduled: false,
        ),
      ],
    );

    await tester.tap(find.byType(SectionEditButton));
    await tester.pumpAndSettle();

    // The confirmation lists the override and the editor has NOT opened yet.
    expect(find.text('This series has individual day edits'), findsOneWidget);
    expect(find.text('Save'), findsNothing);

    // Cancelling keeps the section in read mode.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Save'), findsNothing);
    expect(find.byType(SectionEditButton), findsOneWidget);
  });
}
