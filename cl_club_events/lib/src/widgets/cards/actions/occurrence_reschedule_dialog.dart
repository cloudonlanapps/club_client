import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show SavingDialogCloseIcon, SavingDialogScope;

import '../../../models/occurrence_reschedule_form_helpers.dart';
import '../../../utils/event_write_error_message.dart';

/// Dialog to reschedule a single camp [occurrence] (start / duration / venue).
///
/// Hosts the SDK-free [OccurrenceRescheduleForm], supplies the venue options
/// from the master provider, and drives the form through a `GlobalKey`. On
/// Save it diffs via [OccurrenceRescheduleFormSubmit] and calls the camp
/// master notifier, mapping the server's reschedule guards to friendly
/// messages: on the field a guard is about (a start in the past, a venue
/// that is gone), else inline under the form. A failure that is not about
/// the move is a toast. Pops `true` when a reschedule was applied.
class OccurrenceRescheduleDialog extends ConsumerStatefulWidget {
  const OccurrenceRescheduleDialog({required this.occurrence, super.key});

  final Occurrence occurrence;

  @override
  ConsumerState<OccurrenceRescheduleDialog> createState() =>
      OccurrenceRescheduleDialogState();
}

class OccurrenceRescheduleDialogState
    extends ConsumerState<OccurrenceRescheduleDialog> {
  final _formKey = GlobalKey<OccurrenceRescheduleFormState>();
  bool _submitting = false;

  Future<void> _save() async {
    final values = _formKey.currentState?.validate();
    if (values == null) return;
    if (!(_formKey.currentState?.isDirty ?? false)) {
      // Nothing changed — close without an SDK call.
      Navigator.of(context).pop(false);
      return;
    }

    setState(() => _submitting = true);
    try {
      await OccurrenceRescheduleFormSubmit.updateSchedule(
        occurrence: widget.occurrence,
        values: values,
        notifier: ref.read(clEventsMasterProvider.notifier),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on StaleVersionException catch (e) {
      // The session changed under the admin and the camp master has reloaded
      // it: close the stale form and say who changed it and when.
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(occurrenceRescheduleErrorMessage(e)),
        ),
      );
      Navigator.of(context).pop(false);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      // What the server refuses about the move shows on its field or
      // inline; a failure that is not about it is a toast, and the dialog
      // stays, on again, for another try.
      final refusal = e is ServerException
          ? occurrenceRescheduleRefusal(e)
          : null;
      if (refusal == null) {
        ShadToaster.of(context).show(
          ShadToast.destructive(description: Text(eventWriteErrorMessage(e))),
        );
        return;
      }
      final fieldId = refusal.fieldId;
      if (fieldId == null) {
        _formKey.currentState?.showErrors(formError: refusal.message);
      } else {
        _formKey.currentState?.showErrors(
          fieldErrors: {fieldId: refusal.message},
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final venues =
        (ref
                    .watch(
                      clVenuesProvider(
                        (includeDeleted: false, searchTerm: null),
                      ),
                    )
                    .valueOrNull ??
                const <Venue>[])
            .map((v) => EventVenueOption(id: v.id, name: v.name))
            .toList();

    return SavingDialogScope(
      saving: _submitting,
      child: ShadDialog(
        closeIcon: SavingDialogCloseIcon(saving: _submitting),
        title: const Text('Reschedule Session'),
        description: const Text(
          'Move this session to a new date, time, or venue. Enrolled members '
          'are notified of the change.',
        ),
        actions: [
          ShadButton.outline(
            onPressed: _submitting
                ? null
                : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ShadButton(
            onPressed: _submitting ? null : _save,
            child: Text(_submitting ? 'Saving…' : 'Save'),
          ),
        ],
        child: OccurrenceRescheduleForm(
          key: _formKey,
          initialValues: buildOccurrenceRescheduleInitialValues(
            widget.occurrence,
          ),
          venues: venues,
          enabled: !_submitting,
        ),
      ),
    );
  }
}
