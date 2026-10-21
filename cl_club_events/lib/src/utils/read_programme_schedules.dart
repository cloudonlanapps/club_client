import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventSchedulesProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show EventSchedule;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The schedules of the programme [eventId], or `null` when they cannot be
/// read: the event itself then stands for its current schedule.
///
/// The one place the programme's schedule actions read them with that
/// fallback (club_client#185), so a change to it is made once.
Future<List<EventSchedule>?> readProgrammeSchedules(
  WidgetRef ref,
  int eventId,
) async {
  try {
    return await ref.read(clEventSchedulesProvider(eventId).future);
  } on Object catch (_) {
    return null;
  }
}
