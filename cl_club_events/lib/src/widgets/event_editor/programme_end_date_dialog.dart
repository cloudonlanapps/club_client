import 'package:cl_club_forms/cl_club_forms.dart'
    show
        ProgrammeEndDateForm,
        ProgrammeEndDateFormFields,
        ProgrammeEndDateFormState;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/programme_schedule_form_helpers.dart';
import '../../utils/programme_end_date.dart';
import '../../utils/schedule_save_error.dart';

/// Shown when a programme that had no end date is given one.
const String programmeEndDateSetMessage = 'End date set.';

/// Shown when a programme's end date is moved.
const String programmeEndDateChangedMessage = 'End date changed.';

/// Shown when a programme's end date is removed.
const String programmeEndDateClearedMessage = 'End date cleared.';

/// Shown when the server refuses an end-date change because the end was
/// set, cleared or passed in the meantime.
const String programmeEndDateOutdatedMessage =
    "This programme's end date has changed or has passed. Close this and "
    'check its schedule.';

/// Shown when an end-date change fails with no more specific explanation.
const String programmeEndDateFailedMessage =
    'Could not change the end date. Please try again.';

/// The **Adjust end date** dialog of a programme whose end has not passed:
/// hosts the SDK-free [ProgrammeEndDateForm] and commits through
/// [ProgrammeScheduleFormSubmit.adjustEndDate].
///
/// A programme with no end date sets one, with a reason. One whose end is
/// ahead moves it to another day, or removes it with **Clear end date**. The
/// form states the last session the chosen day gives before anything is
/// saved. A refusal stays in the dialog: on the last day when it is about
/// the day chosen, else as an inline message.
class ProgrammeEndDateDialog extends ConsumerStatefulWidget {
  const ProgrammeEndDateDialog({
    required this.event,
    this.schedules,
    super.key,
  });

  final Event event;

  /// The programme's schedules, when they could be read.
  final List<EventSchedule>? schedules;

  /// The dialog's title.
  static const String title = 'Adjust end date';

  /// The label of the action that removes the end date.
  static const String clearLabel = 'Clear end date';

  /// The widest the dialog's form grows.
  static const double maxFormWidth = 420;

  @override
  ConsumerState<ProgrammeEndDateDialog> createState() =>
      ProgrammeEndDateDialogState();
}

class ProgrammeEndDateDialogState
    extends ConsumerState<ProgrammeEndDateDialog> {
  final formKey = GlobalKey<ProgrammeEndDateFormState>();
  bool saving = false;

  /// Whether the programme has an end date to move or clear.
  bool get hasEnd => widget.event.untilTimeUtc != null;

  Future<void> save() async {
    final form = formKey.currentState;
    if (form == null || saving) return;
    final values = form.validate();
    if (values == null) return;
    if (!form.isDirty) {
      Navigator.of(context).pop();
      return;
    }
    final lastDay = values[ProgrammeEndDateFormFields.lastDayId] as DateTime;
    final cutoff = programmeEndCutoff(
      widget.event,
      lastDay,
      schedules: widget.schedules,
    );
    if (cutoff == null) {
      form.showErrors(
        fieldErrors: const {
          ProgrammeEndDateFormFields.lastDayId:
              programmeEndDateNoSessionMessage,
        },
      );
      return;
    }
    await commit(
      lastDay: lastDay,
      reason: values[ProgrammeEndDateFormFields.reasonId] as String,
      done: hasEnd
          ? programmeEndDateChangedMessage
          : programmeEndDateSetMessage,
    );
  }

  Future<void> clear() async {
    final form = formKey.currentState;
    if (form == null || saving) return;
    await commit(
      lastDay: null,
      reason: form.reason,
      done: programmeEndDateClearedMessage,
    );
  }

  /// Sends the change and closes the dialog with [done], or shows why it
  /// was refused.
  Future<void> commit({
    required DateTime? lastDay,
    required String reason,
    required String done,
  }) async {
    final navigator = Navigator.of(context);
    final toaster = ShadToaster.of(context);
    setState(() => saving = true);
    try {
      await ProgrammeScheduleFormSubmit.adjustEndDate(
        event: widget.event,
        lastDay: lastDay,
        reason: reason,
        notifier: ref.read(clEventsMasterProvider.notifier),
        schedules: widget.schedules,
      );
      navigator.pop();
      toaster.show(ShadToast(description: Text(done)));
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      final message = failureOf(e);
      if (isAboutLastDay(e) && lastDay != null) {
        formKey.currentState?.showErrors(
          fieldErrors: {ProgrammeEndDateFormFields.lastDayId: message},
        );
      } else {
        formKey.currentState?.showErrors(formError: message);
      }
    }
  }

  /// Whether the refusal [error] is about the day chosen: too far ahead, or
  /// a last session too close to now.
  bool isAboutLastDay(Object error) =>
      error is ServerException &&
      (error.code == SdkErrorCode.beyondSchedulingHorizon ||
          error.code == SdkErrorCode.cutoffTooSoon);

  String failureOf(Object error) {
    if (error is ServerException && error.code == SdkErrorCode.invalidState) {
      return programmeEndDateOutdatedMessage;
    }
    return scheduleSaveErrorMessage(
      error,
      fallback: programmeEndDateFailedMessage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    return ShadDialog(
      title: const Text(ProgrammeEndDateDialog.title),
      actions: [
        ShadButton.outline(
          onPressed: saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (hasEnd)
          ShadButton.outline(
            onPressed: saving ? null : clear,
            child: const Text(ProgrammeEndDateDialog.clearLabel),
          ),
        ShadButton(onPressed: saving ? null : save, child: const Text('Save')),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: ProgrammeEndDateDialog.maxFormWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: ProgrammeEndDateForm(
            key: formKey,
            initialValues: buildProgrammeEndDateFormInitialValues(
              event,
              schedules: widget.schedules,
            ),
            reasonRequired: !hasEnd,
            resultOf: (day) => programmeEndResultLine(
              event,
              day,
              schedules: widget.schedules,
            ),
            enabled: !saving,
          ),
        ),
      ),
    );
  }
}
