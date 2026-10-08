import 'package:cl_club_forms/cl_club_forms.dart'
    show ProgrammeEndDateForm, ProgrammeEndDateFormState;
import 'package:club_sdk_2/club_sdk_2.dart' show Event, EventSchedule;
import 'package:flutter/widgets.dart';

import '../../models/programme_schedule_form_helpers.dart';
import '../../utils/programme_end_date.dart';
import 'programme_end_date_dialog.dart';

/// The body of [ProgrammeEndDateDialog]: the SDK-free
/// [ProgrammeEndDateForm], seeded from [event] and stating the last session
/// each chosen day gives. A reason is required only when the programme has
/// no end date yet.
class ProgrammeEndDateDialogBody extends StatelessWidget {
  const ProgrammeEndDateDialogBody({
    required this.formKey,
    required this.event,
    required this.enabled,
    this.schedules,
    super.key,
  });

  /// Drives the hosted form.
  final GlobalKey<ProgrammeEndDateFormState> formKey;

  /// The programme whose end date is adjusted.
  final Event event;

  /// The programme's schedules, when they could be read.
  final List<EventSchedule>? schedules;

  /// Whether the form takes input: off while a save is in flight.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: ProgrammeEndDateDialog.maxFormWidth,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: ProgrammeEndDateForm(
          key: formKey,
          initialValues: buildProgrammeEndDateFormInitialValues(
            event,
            schedules: schedules,
          ),
          reasonRequired: event.untilTimeUtc == null,
          resultOf: (day) =>
              programmeEndResultLine(event, day, schedules: schedules),
          enabled: enabled,
        ),
      ),
    );
  }
}
