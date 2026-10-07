import 'package:cl_club_forms/cl_club_forms.dart';

import '../constants/demo_durations.dart';
import 'demo_samples.dart';

/// Stand-ins for what a host does for a form: they answer with made-up data
/// after a short delay, as a server or a picker dialog would.
abstract final class FakeHostCalls {
  /// The username availability check: a name starting
  /// [DemoSamples.takenPrefix] is taken, any other is free.
  static Future<bool> usernameAvailable(String username) async {
    await Future<void>.delayed(DemoDurations.fakeCall);
    return !username.toLowerCase().startsWith(DemoSamples.takenPrefix);
  }

  /// The organizer picker: always picks the first of
  /// [DemoSamples.pickable].
  static Future<EventStaffMember?> pickOrganizer() async {
    await Future<void>.delayed(DemoDurations.fakeCall);
    return DemoSamples.pickable.first;
  }

  /// The coach picker: picks the first of [DemoSamples.pickable] that is not
  /// in [exclude], or nobody once all are there.
  static Future<List<EventStaffMember>?> pickCoaches(
    Set<String> exclude,
  ) async {
    await Future<void>.delayed(DemoDurations.fakeCall);
    return DemoSamples.pickable
        .where((member) => !exclude.contains(member.username))
        .take(1)
        .toList();
  }

  /// What ending a programme on [day] does, as the host would word it.
  static String endDateResult(DateTime day) =>
      'The last session is on ${day.day}/${day.month}/${day.year}; '
      '3 later sessions are removed.';
}
