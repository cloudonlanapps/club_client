import 'package:cl_club_forms/cl_club_forms.dart'
    show
        EventTimetableForm,
        EventTimetableFormFields,
        EventTimetableFormState,
        EventTimetableFormValidators;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventSchedulesProvider, clEventsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EditableSectionCard;

import '../../models/event_timetable_form_helpers.dart';
import '../../models/stale_version_message.dart';
import '../../utils/event_save_error.dart';
import '../events_preview/cl_event_schedule.dart' show ClEventScheduleBody;
import 'schedule_note.dart';

/// What a timetable correction does, shown under a camp's or one-off's
/// timetable editor.
const String eventTimetableCorrectionNote =
    'A correction changes how every occurrence, past and future, is split '
    'into sessions. No date or time moves.';

/// What a timetable correction does, shown under a programme's timetable
/// editor, set against a split.
const String programmeTimetableCorrectionNote =
    "A correction changes the chosen schedule's sessions for every "
    'occurrence under it, past and future, in place. Changing the timetable '
    'from a date onward is a split of the programme, not a correction.';

/// Inline **timetable correction** section of an event detail page
/// (club_core#85): how each occurrence is split into named sessions,
/// corrected in place at any time, including after the event has started,
/// without moving a date.
///
/// Read mode reuses [ClEventScheduleBody], with [note] as a muted line under
/// it. Edit mode hosts the SDK-free [EventTimetableForm] over the event's
/// schedule — for a programme, over its schedules (`listSchedules`, the
/// latest by default) — and commits via
/// [EventTimetableFormSubmit.updateTimetable].
class EventTimetableSection extends ConsumerStatefulWidget {
  const EventTimetableSection({
    required this.event,
    required this.canEdit,
    this.note,
    this.read,
    this.actions,
    super.key,
  });

  final Event event;

  /// The schedule as shown in read mode; [ClEventScheduleBody] when `null`.
  final Widget? read;

  /// Further actions on the schedule, shown under it in read mode.
  final Widget? actions;

  /// Whether the viewer may correct the timetable (an admin).
  final bool canEdit;

  /// Shown under the schedule in read mode, e.g. why a camp's dates are
  /// fixed.
  final String? note;

  @override
  ConsumerState<EventTimetableSection> createState() =>
      EventTimetableSectionState();
}

class EventTimetableSectionState extends ConsumerState<EventTimetableSection> {
  final formKey = GlobalKey<EventTimetableFormState>();

  bool get isProgramme => widget.event.type == EventType.programme;

  /// Loads a programme's schedules before the editor opens, so the picker
  /// offers all of them from the start. Fails open: without them the editor
  /// corrects the latest schedule, which the event itself describes.
  Future<bool> loadSchedules() async {
    if (!isProgramme) return true;
    try {
      await ref.read(clEventSchedulesProvider(widget.event.id).future);
    } on Object catch (_) {
      // The editor falls back to the event's own (latest) schedule.
    }
    return true;
  }

  /// Sends the correction. True closes the editor; a refusal of the split
  /// shows on the sessions field and keeps it open.
  Future<bool> commit(Map<String, dynamic> values) async {
    final event = widget.event;
    try {
      await EventTimetableFormSubmit.updateTimetable(
        event: event,
        value: eventTimetableValueOf(values),
        notifier: ref.read(clEventsMasterProvider.notifier),
      );
      if (!mounted) return true;
      showToast(const ShadToast(description: Text('Timetable corrected.')));
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
        formKey.currentState?.showErrors(
          fieldErrors: const {
            EventTimetableFormFields.sessionsId:
                EventTimetableFormValidators.totalMismatchMessage,
          },
        );
        return false;
      }
      if (e.code == SdkErrorCode.scheduleNotFound) {
        ref.invalidate(clEventSchedulesProvider(event.id));
        showToast(
          const ShadToast.destructive(
            description: Text(
              'That schedule is no longer part of this event. Its schedules '
              'have been reloaded; check them and try again.',
            ),
          ),
        );
        return true;
      }
      showToast(ShadToast.destructive(description: Text(failureOf(e))));
      return false;
    } on Object catch (e) {
      showToast(ShadToast.destructive(description: Text(failureOf(e))));
      return false;
    }
  }

  String failureOf(Object error) => eventSaveErrorMessage(
    error,
    fallback: 'Could not correct the timetable. Please try again.',
  );

  void showToast(ShadToast toast) {
    if (mounted) ShadToaster.of(context).show(toast);
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final note = widget.note;
    final actions = widget.actions;
    final schedules = isProgramme
        ? ref.watch(clEventSchedulesProvider(event.id)).valueOrNull
        : null;
    return EditableSectionCard<Map<String, dynamic>>(
      title: 'Schedule',
      leadingIcon: LucideIcons.calendarClock,
      canEdit: widget.canEdit,
      editMaxWidth: 560,
      read: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.read ?? ClEventScheduleBody(event: event),
          if (widget.canEdit && note != null) ...[
            const SizedBox(height: 12),
            ScheduleNote(text: note),
          ],
          if (actions != null) ...[const SizedBox(height: 16), actions],
        ],
      ),
      editBuilder: ({required enabled}) => EventTimetableForm(
        key: formKey,
        schedules: buildEventTimetableSchedules(event, schedules: schedules),
        note: isProgramme
            ? programmeTimetableCorrectionNote
            : eventTimetableCorrectionNote,
        enabled: enabled,
      ),
      onValidate: () => formKey.currentState?.validate(),
      isDirty: () => formKey.currentState?.isDirty ?? false,
      onBeforeEdit: loadSchedules,
      onSave: commit,
    );
  }
}
