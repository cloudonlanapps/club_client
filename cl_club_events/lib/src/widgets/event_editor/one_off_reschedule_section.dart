import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventsMasterProvider, clVenuesProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show
        EditableSectionCard,
        EventTimetableFormValidators,
        EventVenueOption,
        OneOffScheduleForm,
        OneOffScheduleFormState,
        OneOffScheduleFormValidators,
        OneOffScheduleValue;

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

  Future<bool> save(OneOffScheduleValue value) async {
    try {
      await OneOffScheduleFormSubmit.updateSchedule(
        event: widget.event,
        value: value,
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
      if (e.code == SdkErrorCode.invalidSessionsTotal) {
        formKey.currentState?.showSessionsError(
          EventTimetableFormValidators.totalMismatchMessage,
        );
        return false;
      }
      if (e.code == SdkErrorCode.postponeOnly) {
        formKey.currentState?.showFormError(
          OneOffScheduleFormValidators.postponeOnlyMessage,
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
    return EditableSectionCard<OneOffScheduleValue>(
      title: 'Schedule',
      leadingIcon: LucideIcons.calendarClock,
      canEdit: widget.canEdit,
      editMaxWidth: 560,
      read: ClEventScheduleBody(event: event),
      editBuilder: () => OneOffScheduleForm(
        key: formKey,
        initialValue: buildOneOffScheduleInitialValues(event),
        venues: [
          for (final venue in venues ?? const <Venue>[])
            EventVenueOption(id: venue.id, name: venue.name),
        ],
        notBefore: event.startTimeUtc,
      ),
      onValidate: () => formKey.currentState?.validate(),
      isDirty: () => formKey.currentState?.isDirty ?? false,
      onSave: save,
    );
  }
}
