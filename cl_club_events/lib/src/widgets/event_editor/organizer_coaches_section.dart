import 'package:cl_club_forms/cl_club_forms.dart'
    show EventStaffForm, EventStaffFormState;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        clEventSchedulesProvider,
        clEventsMasterProvider,
        clUsersMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EditableSectionCard;

import '../../models/camp_event_form_helpers.dart' show EventFormSubmit;
import '../../models/event_staff_form_helpers.dart';
import '../../models/programme_schedule_form_helpers.dart'
    show programmeAdjustFromOptions;
import '../../utils/event_save_error.dart';
import 'event_staff_pickers.dart';
import 'organizer_coaches_read.dart';

/// Organizer & coaches section, edited in place via pickers (no free text).
///
/// Organizer is a single user (admin or coach) changed by **Transfer**; coaches
/// are a coach-only multi-select list. In read mode a coach name is a tappable
/// link to their **public** profile (`onPublicProfileTap`) only when that coach
/// has opted in (`isPublicProfile`); others render as plain text. The editor
/// stages changes and the card's Save commits them in a single call: an
/// update of a camp or a one-off, and for a programme a split from the
/// upcoming session the editor asks for (club_client#118). Coach display
/// names + public ids are resolved from `clUsersMasterProvider`.
class OrganizerCoachesSection extends ConsumerStatefulWidget {
  const OrganizerCoachesSection({
    required this.event,
    this.onPublicProfileTap,
    super.key,
  });

  final Event event;

  /// Opens a coach's public profile by `publicId`; only opted-in coaches
  /// (`isPublicProfile`) are made tappable.
  final ValueChanged<String>? onPublicProfileTap;

  @override
  ConsumerState<OrganizerCoachesSection> createState() =>
      OrganizerCoachesSectionState();
}

class OrganizerCoachesSectionState
    extends ConsumerState<OrganizerCoachesSection> {
  final editorKey = GlobalKey<EventStaffFormState>();

  Future<bool> save(Map<String, dynamic> values) async {
    try {
      await EventFormSubmit.updateOrganizer(
        event: widget.event,
        values: values,
        notifier: ref.read(clEventsMasterProvider.notifier),
      );
      if (!mounted) return true;
      ShadToaster.of(context).show(
        const ShadToast(description: Text('Organizer & coaches updated.')),
      );
      return true;
    } on Object catch (e, st) {
      if (!mounted) return false;
      // An organizer or a coach the server refuses shows on that field, a
      // clash inline; anything else is a failed save.
      final refusal = EventFormSubmit.staffRefusal(e);
      if (refusal != null) {
        editorKey.currentState?.showErrors(
          fieldErrors: refusal.fieldErrors,
          formError: refusal.formError,
        );
        return false;
      }
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            eventSaveErrorMessage(
              e,
              stackTrace: st,
              fallback: 'Could not update. Please try again.',
            ),
          ),
        ),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final master = ref.watch(clUsersMasterProvider).valueOrNull;
    final organizerName = event.organizerName?.trim() ?? '';
    final coachNames = event.coachNames ?? const <String>[];

    final organizer = organizerName.isEmpty
        ? null
        : eventStaffPickerFor(organizerName, master);
    final coaches = [
      for (final u in coachNames) eventStaffPickerFor(u, master),
    ];
    // A programme's staffing changes from a session onward: its editor
    // asks for one of the upcoming sessions of the present schedule.
    final isProgramme = event.type == EventType.programme;
    final schedules = isProgramme
        ? ref.watch(clEventSchedulesProvider(event.id)).valueOrNull
        : null;

    return EditableSectionCard<Map<String, dynamic>>(
      title: 'Organizer & Coaches',
      leadingIcon: LucideIcons.users,
      canEdit: true,
      editMaxWidth: 460,
      read: OrganizerCoachesRead(
        organizer: organizer,
        coaches: coaches,
        master: master,
        onPublicProfileTap: widget.onPublicProfileTap,
      ),
      editBuilder: ({required enabled}) {
        final fromOptions = isProgramme
            ? programmeAdjustFromOptions(event, schedules: schedules)
            : null;
        return EventStaffForm(
          key: editorKey,
          initialValues: buildEventStaffFormInitialValues(
            organizer: organizer,
            coaches: coaches,
            from: fromOptions == null || fromOptions.isEmpty
                ? null
                : fromOptions.first,
          ),
          fromOptions: fromOptions,
          enabled: enabled,
          onPickOrganizer: () async {
            final picked = await pickEventOrganizer(context, ref);
            return picked == null ? null : eventStaffMemberOf(picked);
          },
          onPickCoaches: (exclude) async {
            final picked = await pickEventCoaches(context, ref, exclude);
            return picked?.map(eventStaffMemberOf).toList();
          },
        );
      },
      onValidate: () => editorKey.currentState?.validate(),
      isDirty: () => editorKey.currentState?.isDirty ?? false,
      onSave: save,
    );
  }
}
