import 'package:cl_club_forms/cl_club_forms.dart'
    show
        EventVenueOption,
        ProgrammeScheduleAdjustForm,
        ProgrammeScheduleAdjustFormState;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventsMasterProvider, clVenuesProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/programme_schedule_form_helpers.dart';
import '../../models/stale_version_message.dart';
import '../../utils/programme_end_date.dart';
import '../../utils/schedule_save_error.dart';

/// Shown when a programme's schedule has been adjusted.
const String programmeScheduleAdjustedMessage = 'Schedule adjusted.';

/// Shown when adjusting a programme's schedule fails with no more specific
/// explanation.
const String programmeScheduleAdjustFailedMessage =
    'Could not adjust the schedule. Please try again.';

/// The **Adjust Schedule** dialog of a programme: hosts the SDK-free
/// [ProgrammeScheduleAdjustForm], seeded with the present schedule, and
/// commits one split through [ProgrammeScheduleFormSubmit.adjustSchedule].
///
/// Saving with no term changed closes it and sends nothing. A refusal the
/// admin can act on (a clash with another programme, a From session no
/// longer valid) stays in the dialog as an inline message; a stale version
/// closes it on the reloaded programme and says who changed it.
class ProgrammeAdjustScheduleDialog extends ConsumerStatefulWidget {
  const ProgrammeAdjustScheduleDialog({
    required this.event,
    required this.fromOptions,
    super.key,
  });

  final Event event;

  /// The upcoming session starts the new schedule may begin at.
  final List<DateTime> fromOptions;

  /// The dialog's title.
  static const String title = 'Adjust Schedule';

  /// The widest the dialog's form grows.
  static const double maxFormWidth = 560;

  /// The gap between the end-date warning and the form.
  static const double warningGap = 12;

  @override
  ConsumerState<ProgrammeAdjustScheduleDialog> createState() =>
      ProgrammeAdjustScheduleDialogState();
}

class ProgrammeAdjustScheduleDialogState
    extends ConsumerState<ProgrammeAdjustScheduleDialog> {
  final formKey = GlobalKey<ProgrammeScheduleAdjustFormState>();
  bool saving = false;

  Future<void> save() async {
    final form = formKey.currentState;
    if (form == null || saving) return;
    final value = form.validate();
    if (value == null) return;
    final navigator = Navigator.of(context);
    if (!form.isDirty) {
      navigator.pop();
      return;
    }
    final toaster = ShadToaster.of(context);
    setState(() => saving = true);
    try {
      await ProgrammeScheduleFormSubmit.adjustSchedule(
        event: widget.event,
        value: value,
        notifier: ref.read(clEventsMasterProvider.notifier),
      );
      navigator.pop();
      toaster.show(
        const ShadToast(description: Text(programmeScheduleAdjustedMessage)),
      );
    } on StaleVersionException catch (e) {
      // The master has reloaded the programme: close on it rather than keep
      // terms edited against the old one.
      navigator.pop();
      toaster.show(
        ShadToast.destructive(
          description: Text(staleVersionMessage(e, subject: 'This programme')),
        ),
      );
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      form.showFormError(
        scheduleSaveErrorMessage(
          e,
          fallback: programmeScheduleAdjustFailedMessage,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final endWarning = programmeEndClearedWarning(event);
    final venues = ref
        .watch(clVenuesProvider((includeDeleted: false, searchTerm: null)))
        .valueOrNull;
    return ShadDialog(
      title: const Text(ProgrammeAdjustScheduleDialog.title),
      actions: [
        ShadButton.outline(
          onPressed: saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ShadButton(
          onPressed: saving ? null : save,
          child: const Text('Save'),
        ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: ProgrammeAdjustScheduleDialog.maxFormWidth,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: ProgrammeAdjustScheduleDialog.warningGap,
            children: [
              if (endWarning != null)
                Text(endWarning, style: ShadTheme.of(context).textTheme.small),
              ProgrammeScheduleAdjustForm(
                key: formKey,
                initialValue: buildProgrammeScheduleAdjustInitialValues(
                  event,
                  fromOptions: widget.fromOptions,
                ),
                fromOptions: widget.fromOptions,
                venues: [
                  for (final venue in venues ?? const <Venue>[])
                    EventVenueOption(id: venue.id, name: venue.name),
                ],
                enabled: !saving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
