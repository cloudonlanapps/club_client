import 'dart:typed_data' show Uint8List;

import 'package:cl_club_forms/cl_club_forms.dart'
    show EventStaffForm, EventStaffFormState;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        clEventSchedulesProvider,
        clEventsMasterProvider,
        clUsersMasterProvider,
        clVenueDetailProvider,
        eventCoverImageProvider,
        eventMediaMutationProvider,
        imagePickerProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show
        ConfirmImagePicker,
        EditableMarkdown,
        EditableSectionCard,
        ImageUploadAffordance,
        PickedImage,
        PickerUser,
        pickImageReportingErrors,
        showUserSelectionDialog;

import '../../models/camp_event_form_helpers.dart' show EventFormSubmit;
import '../../models/event_staff_form_helpers.dart';
import '../../models/programme_schedule_form_helpers.dart'
    show programmeAdjustFromOptions;
import '../../utils/event_save_error.dart';
import '../events_preview/cl_event_audit_info.dart';
import '../events_preview/cl_event_enrolments_summary.dart';
import '../events_preview/cl_event_gallery.dart';
import '../events_preview/cl_event_hero.dart';
import '../events_preview/cl_event_pending_requests.dart';
import '../events_preview/cl_event_venue_detail.dart';
import 'event_eligibility_card.dart';
import 'event_management_section.dart';
import 'event_schedule_section.dart';

/// Editable body for an event detail page, shown to whoever may manage the
/// event (an admin or its organizer, `canManageEvent`), mirroring
/// `VenueProfileView`: cover image (avatar-style media upload on the hero),
/// description (markdown), eligibility / organizer (section editors), gallery
/// (media-link tiles), flags (live toggles), and the management actions
/// ([EventManagementSection]).
/// Cover & gallery use the v2 media-link flow; the legacy `galleryUris`
/// field is no longer read. The schedule section depends on the event type
/// ([EventScheduleSection]); the venue stays read-only here.
class EditableEventBody extends ConsumerWidget {
  const EditableEventBody({
    required this.event,
    required this.currentUser,
    this.venue,
    this.onVenueTap,
    this.onManageEnrolments,
    this.onMemberTap,
    this.onPublicProfileTap,
    this.onDeleted,
    super.key,
  });

  final Event event;
  final UserPrivate currentUser;
  final Venue? venue;
  final ValueChanged<int>? onVenueTap;
  final ValueChanged<int>? onManageEnrolments;
  final ValueChanged<String>? onMemberTap;

  /// Opens a coach's public profile by `publicId` (opted-in coaches only).
  final ValueChanged<String>? onPublicProfileTap;

  /// Leaves the page once the event has been deleted (Event Management).
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EventOverviewCard(event: event),
          const SizedBox(height: 16),
          EventScheduleSection(event: event, canEdit: true),
          const SizedBox(height: 16),
          EventEligibilityCard(event: event),
          const SizedBox(height: 16),
          OrganizerCoachesSection(
            event: event,
            onPublicProfileTap: onPublicProfileTap,
          ),
          const SizedBox(height: 16),
          ClEventGallery(eventId: event.id, canEdit: true),
          const SizedBox(height: 16),
          EventFlagsCard(event: event),
          const SizedBox(height: 16),
          ClEventVenueDetail(
            venueId: event.venueId,
            venue:
                venue ??
                ref.watch(clVenueDetailProvider(event.venueId)).valueOrNull,
            onVenueTap: onVenueTap,
          ),
          const SizedBox(height: 16),
          EventManagementSection(
            event: event,
            currentUser: currentUser,
            onDeleted: onDeleted,
          ),
          const SizedBox(height: 16),
          ClEventPendingRequests(
            eventId: event.id,
            currentUser: currentUser,
            onManageEnrolments: onManageEnrolments,
            onMemberTap: onMemberTap,
          ),
          const SizedBox(height: 12),
          ClEventEnrolmentsSummary(
            eventId: event.id,
            currentUser: currentUser,
            onManageEnrolments: onManageEnrolments,
            onMemberTap: onMemberTap,
          ),
          const SizedBox(height: 16),
          ClEventAuditInfo(event: event, currentUser: currentUser),
        ],
      ),
    );
  }
}

/// Hero card with the cover image and the event title, plus the description
/// edited inline via [EditableMarkdown].
class EventOverviewCard extends ConsumerWidget {
  const EventOverviewCard({required this.event, super.key});

  final Event event;

  Future<void> _saveDescription(
    BuildContext context,
    WidgetRef ref,
    String updated,
  ) async {
    try {
      await EventFormSubmit.updateDescription(
        event: event,
        description: updated,
        notifier: ref.read(clEventsMasterProvider.notifier),
      );
    } on Object catch (e, st) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            eventSaveErrorMessage(
              e,
              stackTrace: st,
              fallback: 'Could not update description. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClEventCover(event: event),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: EventCoverUploadAffordance(eventId: event.id),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(event.title, style: theme.textTheme.h4),
                const SizedBox(height: 12),
                EditableMarkdown(
                  data: event.description,
                  label: 'Description',
                  emptyText: 'No description provided.',
                  onSave: (updated) => _saveDescription(context, ref, updated),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
  final _editorKey = GlobalKey<EventStaffFormState>();

  PickerUser _pickerFor(String username, Map<String, UserInfo>? master) {
    final info = master?[username];
    if (info == null) {
      return PickerUser(username: username, displayName: username);
    }
    return PickerUser(
      username: username,
      displayName: info.displayName,
      firstName: info.firstName,
      lastName: info.lastName,
      nickname: info.nickname,
      isAdmin: info.roles.isAdmin,
      isCoach: info.roles.isCoach,
    );
  }

  /// Tap handler that opens a coach's public profile — non-null (tappable)
  /// only when the coach has opted into a public profile.
  VoidCallback? _publicProfileTapFor(
    String username,
    Map<String, UserInfo>? master,
  ) {
    final info = master?[username];
    final onTap = widget.onPublicProfileTap;
    if (info == null || !info.isPublicProfile || onTap == null) return null;
    return () => onTap(info.publicId);
  }

  List<PickerUser> _candidates(
    Map<String, UserInfo> master, {
    required bool Function(UserInfo) where,
    Set<String> exclude = const {},
  }) {
    final list =
        master.entries
            .where(
              (e) =>
                  !e.value.isSuperAdmin &&
                  where(e.value) &&
                  !exclude.contains(e.key),
            )
            .map((e) => _pickerFor(e.key, master))
            .toList()
          ..sort((a, b) => a.displayName.compareTo(b.displayName));
    return list;
  }

  Future<PickerUser?> _pickOrganizer() async {
    final master = await ref.read(clUsersMasterProvider.future);
    if (!mounted) return null;
    final candidates = _candidates(
      master,
      where: (u) => u.roles.isAdmin || u.roles.isCoach,
    );
    final picked = await showUserSelectionDialog(
      context,
      title: 'Transfer organizer',
      description: 'Organizer must be an admin or a coach.',
      users: candidates,
      confirmLabel: 'Transfer',
      showRoleFilter: false,
      singleSelect: true,
    );
    if (picked == null || picked.isEmpty) return null;
    return candidates.firstWhere((c) => c.username == picked.first);
  }

  Future<List<PickerUser>?> _pickCoaches(Set<String> exclude) async {
    final master = await ref.read(clUsersMasterProvider.future);
    if (!mounted) return null;
    final candidates = _candidates(
      master,
      where: (u) => u.roles.isCoach,
      exclude: exclude,
    );
    final picked = await showUserSelectionDialog(
      context,
      title: 'Add coaches',
      users: candidates,
      confirmLabel: 'Add',
      emptyText: 'No more coaches to add.',
      showRoleFilter: false,
    );
    if (picked == null) return null;
    final set = picked.toSet();
    return candidates.where((c) => set.contains(c.username)).toList();
  }

  Future<bool> _save(Map<String, dynamic> values) async {
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
        _editorKey.currentState?.showErrors(
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
    final theme = ShadTheme.of(context);
    final event = widget.event;
    final master = ref.watch(clUsersMasterProvider).valueOrNull;
    final organizerName = event.organizerName?.trim() ?? '';
    final coachNames = event.coachNames ?? const <String>[];

    final organizer = organizerName.isEmpty
        ? null
        : _pickerFor(organizerName, master);
    final coaches = [for (final u in coachNames) _pickerFor(u, master)];
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
      read: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Organizer', style: theme.textTheme.small),
          const SizedBox(height: 4),
          Text(
            organizer?.displayName ?? 'Unassigned',
            style: theme.textTheme.p,
          ),
          const SizedBox(height: 12),
          Text('Coaches', style: theme.textTheme.small),
          const SizedBox(height: 4),
          if (coaches.isEmpty)
            Text('No coaches assigned.', style: theme.textTheme.muted)
          else
            for (final coach in coaches)
              _ReadCoachRow(
                coach: coach,
                onTap: _publicProfileTapFor(coach.username, master),
              ),
        ],
      ),
      editBuilder: ({required enabled}) {
        final fromOptions = isProgramme
            ? programmeAdjustFromOptions(event, schedules: schedules)
            : null;
        return EventStaffForm(
          key: _editorKey,
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
            final picked = await _pickOrganizer();
            return picked == null ? null : eventStaffMemberOf(picked);
          },
          onPickCoaches: (exclude) async {
            final picked = await _pickCoaches(exclude);
            return picked?.map(eventStaffMemberOf).toList();
          },
        );
      },
      onValidate: () => _editorKey.currentState?.validate(),
      isDirty: () => _editorKey.currentState?.isDirty ?? false,
      onSave: _save,
    );
  }
}

/// A tappable coach row in read mode: bullet + name, routing to the member on
/// tap when a handler is supplied.
class _ReadCoachRow extends StatelessWidget {
  const _ReadCoachRow({required this.coach, this.onTap});

  final PickerUser coach;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final row = Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text('• ${coach.displayName}', style: theme.textTheme.p),
    );
    if (onTap == null) return row;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: MouseRegion(cursor: SystemMouseCursors.click, child: row),
    );
  }
}

/// Circular pencil affordance overlaid on the cover image — lets an admin
/// replace (and, when one exists, remove) the event cover. Uploads go through
/// the v2 media-link flow (`eventMediaMutationProvider`), like the user avatar.
class EventCoverUploadAffordance extends ConsumerStatefulWidget {
  const EventCoverUploadAffordance({required this.eventId, super.key});

  final int eventId;

  @override
  ConsumerState<EventCoverUploadAffordance> createState() =>
      EventCoverUploadAffordanceState();
}

class EventCoverUploadAffordanceState
    extends ConsumerState<EventCoverUploadAffordance> {
  /// Picks + confirms an image, then uploads it as the event cover. The
  /// re-entrancy guard lives in [ImageUploadAffordance]; this only owns the
  /// SDK call and its error toast.
  Future<void> _replace() async {
    final picked = await pickAndConfirmEventImage(
      context,
      picker: ref.read(imagePickerProvider),
    );
    if (picked == null || !mounted) return;
    try {
      await ref
          .read(eventMediaMutationProvider(widget.eventId).notifier)
          .uploadCover(
            bytes: picked.bytes,
            filename: picked.filename,
            contentType: picked.mimeType,
          );
    } on Object catch (e, st) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            eventSaveErrorMessage(
              e,
              stackTrace: st,
              fallback: 'Could not update cover. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _remove() async {
    try {
      await ref
          .read(eventMediaMutationProvider(widget.eventId).notifier)
          .clearCover();
    } on Object catch (e, st) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            eventSaveErrorMessage(
              e,
              stackTrace: st,
              fallback: 'Could not remove cover. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploading = ref
        .watch(eventMediaMutationProvider(widget.eventId))
        .isLoading;
    final hasCover =
        ref.watch(eventCoverImageProvider(widget.eventId)).valueOrNull != null;
    return ImageUploadAffordance(
      uploading: uploading,
      onReplace: _replace,
      onRemove: hasCover ? _remove : null,
    );
  }
}

/// Opens the native image picker, then a confirm preview. Returns the picked
/// image when the user confirms, else `null`.
Future<PickedImage?> pickAndConfirmEventImage(
  BuildContext context, {
  required ConfirmImagePicker picker,
}) async {
  final picked = await pickImageReportingErrors(context, picker: picker);
  if (picked == null || !context.mounted) return null;
  final confirmed = await showShadDialog<bool>(
    context: context,
    builder: (_) => EventImagePreviewDialog(picked: picked),
  );
  return confirmed == true ? picked : null;
}

/// Preview dialog showing the picked image with Cancel / Upload actions.
class EventImagePreviewDialog extends StatelessWidget {
  const EventImagePreviewDialog({required this.picked, super.key});

  final PickedImage picked;

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: const Text('Upload image'),
      child: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.memory(
                  Uint8List.fromList(picked.bytes),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ShadButton.ghost(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ShadButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Upload'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Boolean flags — toggling a checkbox immediately persists the change
/// (disabled while a save is in flight). Mirrors `VenueFlagsCard`.
class EventFlagsCard extends ConsumerStatefulWidget {
  const EventFlagsCard({required this.event, super.key});

  final Event event;

  @override
  ConsumerState<EventFlagsCard> createState() => EventFlagsCardState();
}

class EventFlagsCardState extends ConsumerState<EventFlagsCard> {
  bool isSaving = false;

  Future<void> handleToggle({Visibility? visibility, bool? isFeatured}) async {
    setState(() => isSaving = true);
    try {
      await EventFormSubmit.updateFlags(
        event: widget.event,
        notifier: ref.read(clEventsMasterProvider.notifier),
        visibility: visibility,
        isFeatured: isFeatured,
      );
    } on Object catch (e, st) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            eventSaveErrorMessage(
              e,
              stackTrace: st,
              fallback: 'Could not update event. Please try again.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final isPrivate = event.visibility == Visibility.private;
    return ShadCard(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShadCheckbox(
            value: isPrivate,
            enabled: !isSaving,
            onChanged: (v) => handleToggle(
              visibility: v ? Visibility.private : Visibility.public,
            ),
            label: const Text('This is a private event'),
          ),
          const SizedBox(height: 12),
          ShadCheckbox(
            value: event.isFeatured,
            enabled: !isSaving,
            onChanged: (v) => handleToggle(isFeatured: v),
            label: const Text('This event is featured'),
          ),
        ],
      ),
    );
  }
}
