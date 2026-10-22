import 'package:cl_club_events/src/widgets/schedule_clash/schedule_clash_dialog.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

/// A clashing event for a [ConflictReport]: [title], of [type], with one
/// overlapping session per entry of [windows] (each the other event's start
/// and end).
EventConflictItem clashingEvent(
  String title, {
  String type = 'programme',
  int eventId = 90,
  List<(DateTime, DateTime)> windows = const [],
}) => EventConflictItem(
  eventId: eventId,
  eventTitle: title,
  eventType: type,
  occurrences: [
    for (final (start, end) in windows)
      OccurrencePair(
        targetStartUtc: start,
        targetEndUtc: end,
        otherStartUtc: start,
        otherEndUtc: end,
      ),
  ],
);

/// The 409 `SCHEDULE_CONFLICT` a schedule write is refused with, carrying
/// the clashes of each gate.
ScheduleConflictException scheduleClash({
  List<EventConflictItem> venue = const [],
  List<EventConflictItem> organizer = const [],
  List<EventConflictItem> coach = const [],
}) => ScheduleConflictException(
  message: 'raw clash text',
  report: ConflictReport(
    venueConflicts: venue,
    organizerConflicts: organizer,
    coachConflicts: coach,
  ),
);

/// A clash with one coach's other programme, and nothing else.
ScheduleConflictException coachOnlyClash() => scheduleClash(
  coach: [
    clashingEvent(
      'Evening squad',
      windows: [(DateTime.utc(2030, 6, 1, 17), DateTime.utc(2030, 6, 1, 18))],
    ),
  ],
);

/// A clash at the venue with another camp, and nothing else.
ScheduleConflictException venueClash() => scheduleClash(
  venue: [
    clashingEvent(
      'Summer camp',
      type: 'camp',
      windows: [(DateTime.utc(2030, 6, 1, 9), DateTime.utc(2030, 6, 1, 12))],
    ),
  ],
);

/// The clash dialog, while it is open.
final Finder clashDialog = find.byType(ScheduleClashDialog);

/// Chooses Save anyway in the open clash dialog.
Future<void> saveAnyway(WidgetTester tester) async {
  await tester.tap(find.text(ScheduleClashDialog.saveAnywayLabel));
  await tester.pumpAndSettle();
}

/// Chooses Cancel in the open clash dialog.
Future<void> cancelClash(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: clashDialog,
      matching: find.text(ScheduleClashDialog.cancelLabel),
    ),
  );
  await tester.pumpAndSettle();
}

/// Records the `acceptConflicts` of each schedule write a fake receives,
/// refusing one that does not accept with [clash] while it is set.
class ClashingWrites {
  /// The `acceptConflicts` each write sent, in order.
  final List<bool> accepts = [];

  /// The clash a write that does not accept is refused with; `null` lets
  /// every write through.
  ScheduleConflictException? clash;

  /// Records a write; throws [clash] unless it accepted.
  void record({required bool acceptConflicts}) {
    accepts.add(acceptConflicts);
    final refusal = clash;
    if (refusal != null && !acceptConflicts) throw refusal;
  }
}
