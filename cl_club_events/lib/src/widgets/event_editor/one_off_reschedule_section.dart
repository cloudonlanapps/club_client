import 'package:cl_club_forms/cl_club_forms.dart'
    show
        EventVenueOption,
        OneOffScheduleForm,
        OneOffScheduleFormFields,
        OneOffScheduleFormState,
        OneOffScheduleFormValidators;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventsMasterProvider, clVenuesProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EditableSectionCard;

import '../../models/one_off_schedule_form_helpers.dart';
import '../../models/stale_version_message.dart';
import '../../utils/schedule_save_error.dart';
import '../events_preview/cl_event_schedule.dart' show ClEventScheduleBody;

/// Shown when a one-off has been moved.
const String oneOffScheduleUpdatedMessage = 'Schedule updated.';

/// Shown when moving a one-off fails with no more specific explanation.
const String oneOffScheduleFailedMessage =
    'Could not update the schedule. Please try again.';

/// Inline schedule (reschedule) section of a one-off that can still be
/// moved: its date, start time, duration, venue and sessions.
///
/// Read mode reuses [ClEventScheduleBody]; edit mode hosts the SDK-free
/// [OneOffScheduleForm] and commits one reschedule through
/// [OneOffScheduleFormSubmit.updateSchedule].
class OneOffRescheduleSection extends ConsumerStatefulWidget {
  const OneOffRescheduleSection({
    required this.event,
    required this.canEdit,
    super.key,
  });

  final Event event;

  /// Whether the viewer may move the one-off (an admin or its organizer).
  final bool canEdit;

  @override
  ConsumerState<OneOffRescheduleSection> createState() =>
      OneOffRescheduleSectionState();
}

class OneOffRescheduleSectionState
    extends ConsumerState<OneOffRescheduleSection> {
  final formKey = GlobalKey<OneOffScheduleFormState>();

  /// Sends the move. True closes the editor; a refusal about a field shows
  /// on that field, the postpone-only rule inline, and both keep it open.
  Future<bool> commit(Map<String, dynamic> values) async {
    try {
      await OneOffScheduleFormSubmit.updateSchedule(
        event: widget.event,
        value: oneOffScheduleValueOf(values),
        notifier: ref.read(clEventsMasterProvider.notifier),
      );
      showToast(
        const ShadToast(description: Text(oneOffScheduleUpdatedMessage)),
      );
      return true;
    } on StaleVersionException catch (e) {
      // The master has reloaded the event: close the editor on it rather
      // than keep edits made against the old one.
      showToast(
        ShadToast.destructive(
          description: Text(staleVersionMessage(e, subject: 'This event')),
        ),
      );
      return true;
    } on ServerException catch (e) {
      final fieldId = refusedFieldId(e);
      if (fieldId != null) {
        formKey.currentState?.showErrors(fieldErrors: {fieldId: failureOf(e)});
        return false;
      }
      if (e.code == SdkErrorCode.postponeOnly) {
        formKey.currentState?.showErrors(
          formError: OneOffScheduleFormValidators.postponeOnlyMessage,
        );
        return false;
      }
      showToast(ShadToast.destructive(description: Text(failureOf(e))));
      return false;
    } on Object catch (e) {
      showToast(ShadToast.destructive(description: Text(failureOf(e))));
      return false;
    }
  }

  /// The id of the form's field the refusal [e] is about, or `null` when
  /// it is about none of them.
  String? refusedFieldId(ServerException e) => switch (e.code) {
    SdkErrorCode.invalidSessionsTotal => OneOffScheduleFormFields.sessionsId,
    SdkErrorCode.venueNotFound => OneOffScheduleFormFields.venueId,
    SdkErrorCode.beyondSchedulingHorizon => OneOffScheduleFormFields.scheduleId,
    _ => null,
  };

  String failureOf(Object error) =>
      scheduleSaveErrorMessage(error, fallback: oneOffScheduleFailedMessage);

  void showToast(ShadToast toast) {
    if (mounted) ShadToaster.of(context).show(toast);
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final venues = widget.canEdit
        ? ref
              .watch(
                clVenuesProvider((includeDeleted: false, searchTerm: null)),
              )
              .valueOrNull
        : null;
    return EditableSectionCard<Map<String, dynamic>>(
      title: 'Schedule',
      leadingIcon: LucideIcons.calendarClock,
      canEdit: widget.canEdit,
      editMaxWidth: 560,
      read: ClEventScheduleBody(event: event),
      editBuilder: ({required enabled}) => OneOffScheduleForm(
        key: formKey,
        initialValue: buildOneOffScheduleInitialValues(event),
        venues: [
          for (final venue in venues ?? const <Venue>[])
            EventVenueOption(id: venue.id, name: venue.name),
        ],
        notBefore: event.startTimeUtc,
        enabled: enabled,
      ),
      onValidate: () => formKey.currentState?.validate(),
      isDirty: () => formKey.currentState?.isDirty ?? false,
      onSave: commit,
    );
  }
}
