import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEventsMasterNotifier, clEventsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show Event, UserPrivate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ConfirmDialog;

import '../../models/camp_event_form_helpers.dart' show EventFormSubmit;
import '../../models/event_management_action.dart';
import '../../models/event_management_messages.dart';
import '../../utils/event_management_error.dart';
import 'event_cancellation_actions.dart';
import 'event_management_card.dart';
import 'event_rename_dialog.dart';

/// Management actions of an event, on its detail page.
///
/// | Action | Who | Shown when |
/// |---|---|---|
/// | Rename | whoever may manage the event | the event is not archived |
/// | Archive | admin | the event is not archived |
/// | Unarchive | admin | the event is archived |
/// | Delete | super admin | the event is archived |
///
/// Archive is the server's soft delete, Unarchive its restore and Delete
/// its hard delete, which it accepts only for an archived event
/// (club_client#36). Archive and Delete ask for confirmation. After a
/// Delete the page is left through [onDeleted].
///
/// Between Rename and Archive come the actions that call the event off and
/// take that back, by type ([EventCancellationActions], club_client#40).
class EventManagementSection extends ConsumerStatefulWidget {
  const EventManagementSection({
    required this.event,
    required this.currentUser,
    this.onDeleted,
    super.key,
  });

  final Event event;

  /// The viewer, whose roles decide which actions are offered.
  final UserPrivate currentUser;

  /// Leaves the page once the event has been deleted. Supplied by the
  /// screen.
  final VoidCallback? onDeleted;

  @override
  ConsumerState<EventManagementSection> createState() =>
      EventManagementSectionState();
}

class EventManagementSectionState
    extends ConsumerState<EventManagementSection> {
  bool isBusy = false;

  /// Runs [change] on the events master, then toasts [done], or a readable
  /// message when it is refused ([failed] when there is no better one).
  /// Returns whether it succeeded.
  ///
  /// The toaster is taken before the call: a Delete removes the event, and
  /// with it this card, before the toast is shown.
  Future<bool> runChange(
    Future<void> Function(ClEventsMasterNotifier notifier) change, {
    required String done,
    required String failed,
  }) async {
    final toaster = ShadToaster.of(context);
    setState(() => isBusy = true);
    try {
      await change(ref.read(clEventsMasterProvider.notifier));
      toaster.show(ShadToast(description: Text(done)));
      return true;
    } on Object catch (e, st) {
      toaster.show(
        ShadToast.destructive(
          description: Text(
            eventManagementErrorMessage(e, stackTrace: st, fallback: failed),
          ),
        ),
      );
      return false;
    } finally {
      if (mounted) setState(() => isBusy = false);
    }
  }

  /// Renames the event through the rename dialog, which stays open until
  /// the title is saved; a refusal shows on its field.
  Future<void> handleRename() async {
    final toaster = ShadToaster.of(context);
    final newName = await showEventRenameDialog(
      context,
      widget.event.title,
      onSave: writeTitle,
    );
    if (newName == null) return;
    toaster.show(
      const ShadToast(description: Text(EventManagementMessages.renamed)),
    );
  }

  /// Writes [title]; `null` once saved, else the refusal, said for people.
  Future<String?> writeTitle(String title) async {
    try {
      await EventFormSubmit.updateTitle(
        eventId: widget.event.id,
        title: title,
        notifier: ref.read(clEventsMasterProvider.notifier),
      );
      return null;
    } on Object catch (e, st) {
      return eventManagementErrorMessage(
        e,
        stackTrace: st,
        fallback: EventManagementMessages.renameFailed,
      );
    }
  }

  Future<void> handleArchive() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: EventManagementMessages.archiveTitle,
      message: EventManagementMessages.archiveConfirm(widget.event.title),
      confirmLabel: EventManagementMessages.archive,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await runChange(
      (notifier) => notifier.deleteEvent(widget.event.id),
      done: EventManagementMessages.archived,
      failed: EventManagementMessages.archiveFailed,
    );
  }

  Future<void> handleUnarchive() async {
    await runChange(
      (notifier) => notifier.restoreEvent(widget.event.id),
      done: EventManagementMessages.unarchived,
      failed: EventManagementMessages.unarchiveFailed,
    );
  }

  Future<void> handleDelete() async {
    final onDeleted = widget.onDeleted;
    final eventId = widget.event.id;
    final confirmed = await ConfirmDialog.show(
      context,
      title: EventManagementMessages.deleteTitle,
      message: EventManagementMessages.deleteConfirm(widget.event.title),
      confirmLabel: EventManagementMessages.delete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final deleted = await runChange(
      (notifier) => notifier.hardDeleteEvent(eventId),
      done: EventManagementMessages.deleted,
      failed: EventManagementMessages.deleteFailed,
    );
    if (deleted) onDeleted?.call();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.currentUser;
    final archived = !widget.event.isActive;
    EventManagementAction action(String label, VoidCallback onPressed) =>
        (label: label, onPressed: isBusy ? null : onPressed);
    return EventCancellationActions(
      event: widget.event,
      currentUser: user,
      builder: (context, cancellationActions) => EventManagementCard(
        actions: [
          if (!archived) action(EventManagementMessages.rename, handleRename),
          ...cancellationActions,
          if (!archived && user.isAdmin)
            action(EventManagementMessages.archive, handleArchive),
          if (archived && user.isAdmin)
            action(EventManagementMessages.unarchive, handleUnarchive),
          if (archived && user.isSuperAdmin)
            action(EventManagementMessages.delete, handleDelete),
        ],
      ),
    );
  }
}
