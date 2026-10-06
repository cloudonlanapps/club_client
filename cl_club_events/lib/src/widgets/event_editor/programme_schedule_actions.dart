import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventSchedulesProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/programme_schedule_form_helpers.dart';
import '../../utils/programme_end_date.dart';
import 'programme_adjust_schedule_dialog.dart';
import 'programme_end_date_dialog.dart';
import 'schedule_note.dart';

/// Shown when a programme has no upcoming session an adjustment could start
/// from.
const String programmeNoUpcomingSessionMessage =
    'This programme has no upcoming session to adjust its schedule from.';

/// The actions of a programme's Schedule block that change its schedule
/// from a session onward, for an admin or the organizer: **Adjust
/// Schedule** and **Adjust end date**.
///
/// Once the programme's end has passed, Adjust end date is shown locked,
/// with the reason beside it.
class ProgrammeScheduleActions extends ConsumerStatefulWidget {
  const ProgrammeScheduleActions({required this.event, super.key});

  final Event event;

  /// The label of the Adjust Schedule action.
  static const String adjustScheduleLabel = 'Adjust Schedule';

  /// The label of the Adjust end date action.
  static const String adjustEndDateLabel = 'Adjust end date';

  @override
  ConsumerState<ProgrammeScheduleActions> createState() =>
      ProgrammeScheduleActionsState();
}

class ProgrammeScheduleActionsState
    extends ConsumerState<ProgrammeScheduleActions> {
  /// Whether an action is loading what its dialog needs.
  bool opening = false;

  /// The programme's schedules, or `null` when they cannot be read: the
  /// event itself then stands for its current schedule.
  Future<List<EventSchedule>?> loadSchedules() async {
    try {
      return await ref.read(clEventSchedulesProvider(widget.event.id).future);
    } on Object catch (_) {
      return null;
    }
  }

  Future<void> adjustSchedule() async {
    if (opening) return;
    setState(() => opening = true);
    final schedules = await loadSchedules();
    if (!mounted) return;
    setState(() => opening = false);
    final event = widget.event;
    final fromOptions = programmeAdjustFromOptions(event, schedules: schedules);
    if (fromOptions.isEmpty) {
      ShadToaster.of(context).show(
        const ShadToast(description: Text(programmeNoUpcomingSessionMessage)),
      );
      return;
    }
    await showShadDialog<void>(
      context: context,
      builder: (_) => ProgrammeAdjustScheduleDialog(
        event: event,
        fromOptions: fromOptions,
      ),
    );
  }

  Future<void> adjustEndDate() async {
    if (opening) return;
    setState(() => opening = true);
    final schedules = await loadSchedules();
    if (!mounted) return;
    setState(() => opening = false);
    await showShadDialog<void>(
      context: context,
      builder: (_) =>
          ProgrammeEndDateDialog(event: widget.event, schedules: schedules),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ended = programmeHasEnded(widget.event);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ShadButton.outline(
              size: ShadButtonSize.sm,
              onPressed: opening ? null : adjustSchedule,
              child: const Text(ProgrammeScheduleActions.adjustScheduleLabel),
            ),
            ShadButton.outline(
              size: ShadButtonSize.sm,
              onPressed: opening || ended ? null : adjustEndDate,
              child: const Text(ProgrammeScheduleActions.adjustEndDateLabel),
            ),
          ],
        ),
        if (ended) const ScheduleNote(text: programmeEndedMessage),
      ],
    );
  }
}
