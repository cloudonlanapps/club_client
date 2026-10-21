import 'package:cl_club_events/src/utils/read_programme_schedules.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventSchedulesProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/programme_fixtures.dart';

/// Reads the schedules of event 1 through [readProgrammeSchedules] over
/// [schedules], and returns what it gave.
Future<List<EventSchedule>?> _read(
  WidgetTester tester,
  Future<List<EventSchedule>> Function() schedules,
) async {
  late WidgetRef widgetRef;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clEventSchedulesProvider.overrideWith((ref, id) => schedules()),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          widgetRef = ref;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  List<EventSchedule>? read;
  await tester.runAsync(() async {
    read = await readProgrammeSchedules(widgetRef, 1);
  });
  return read;
}

void main() {
  group("Issue 185: one helper reads a programme's schedules", () {
    testWidgets('Issue 185: it gives the schedules when they can be read', (
      tester,
    ) async {
      final schedule = scheduleFixture(1, localNoon(-20).toUtc());

      expect(await _read(tester, () async => [schedule]), [schedule]);
    });

    testWidgets('Issue 185: it gives null when they cannot be read, so the '
        'event stands for its current schedule', (tester) async {
      expect(
        await _read(tester, () async => throw StateError('offline')),
        isNull,
      );
    });
  });
}
