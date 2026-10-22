import 'package:club_sdk_2/club_sdk_2.dart' show ScheduleConflictException;
import 'package:flutter/widgets.dart';

import '../widgets/schedule_clash/schedule_clash_dialog.dart';

/// Runs [write], a save of an event's schedule or staff, and lets the
/// organizer decide on a clash (club_server#72, club_client#278).
///
/// [write] is first sent with `acceptConflicts: false`. When the server
/// refuses it as a clash ([ScheduleConflictException]; nothing was saved),
/// the [ScheduleClashDialog] over [context] lists the clashes; on **Save
/// anyway** the same [write] is sent again with `acceptConflicts: true`.
///
/// Returns `true` once saved, and `false` when the organizer cancels, so
/// the caller goes back to its form with the input kept. Any other failure,
/// including one of the accepted re-send, is rethrown for the caller to
/// report as it does today.
Future<bool> saveConfirmingScheduleClash(
  BuildContext context,
  Future<void> Function({required bool acceptConflicts}) write,
) async {
  try {
    await write(acceptConflicts: false);
    return true;
  } on ScheduleConflictException catch (clash) {
    if (!context.mounted) return false;
    final accepted = await ScheduleClashDialog.show(
      context,
      report: clash.report,
    );
    if (!accepted) return false;
    await write(acceptConflicts: true);
    return true;
  }
}
