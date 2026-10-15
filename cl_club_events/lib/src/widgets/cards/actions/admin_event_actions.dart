import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

import '../../../models/event_management_messages.dart';
import '../../../utils/event_management_error.dart';

/// Resolves the staff actions for a single event row.
///
/// Active events expose `[Enrollments]` as the inline primary action, to
/// the event's staff: an admin, its organizer, or a coach assigned to it
/// (`canManageAttendance`). The list it opens is read-only to an assigned
/// coach, who may read enrollments but not change them; the Assign /
/// Invite bar and the row actions there are organizer-or-admin
/// (`canManageEnrollments`, club_core#136). A coach not on the event sees
/// no actions. Edit and Delete are reserved for the event detail screen
/// (where the confirmation dialog and edit form already live).
///
/// An archived event exposes `[Unarchive]` in the same place, to an admin
/// only (who alone may archive and unarchive); everyone else sees no
/// action on it.
///
/// Hosts the resolved actions and hands them to [builder] as a typed
/// `List<ActionItem>` — the caller wraps them into an [EntityCard] via
/// `trailingActions:`. The list is empty when the acting user is not on
/// the event's staff or no enrollments callback is wired.
class AdminEventActions extends ConsumerStatefulWidget {
  const AdminEventActions({
    required this.event,
    required this.onEnrollments,
    required this.builder,
    super.key,
  });

  final Event event;
  final VoidCallback? onEnrollments;

  /// Receives the resolved actions and returns the host widget (typically
  /// an [EntityCard] with `trailingActions:`).
  final Widget Function(BuildContext context, List<ActionItem> actions) builder;

  @override
  ConsumerState<AdminEventActions> createState() => AdminEventActionsState();
}

/// State of [AdminEventActions].
class AdminEventActionsState extends ConsumerState<AdminEventActions> {
  /// Whether an unarchive is in flight.
  bool isUnarchiving = false;

  /// Unarchives the event, then toasts the outcome.
  Future<void> unarchive() async {
    final toaster = ShadToaster.of(context);
    setState(() => isUnarchiving = true);
    try {
      await ref
          .read(clEventsMasterProvider.notifier)
          .restoreEvent(widget.event.id);
      toaster.show(
        const ShadToast(description: Text(EventManagementMessages.unarchived)),
      );
    } on Object catch (e, st) {
      toaster.show(
        ShadToast.destructive(
          description: Text(
            eventManagementErrorMessage(
              e,
              stackTrace: st,
              fallback: EventManagementMessages.unarchiveFailed,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isUnarchiving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final actingUser = ref.watch(authStateProvider).valueOrNull;
    final actions = <ActionItem>[
      if (!event.isActive && (actingUser?.isAdmin ?? false))
        ActionItem(
          label: EventManagementMessages.unarchive,
          onPressed: isUnarchiving ? null : unarchive,
          loading: isUnarchiving,
        ),
      if (event.isActive &&
          actingUser != null &&
          canManageAttendance(event, actingUser) &&
          widget.onEnrollments != null)
        ActionItem(label: 'Enrollments', onPressed: widget.onEnrollments),
    ];
    return widget.builder(context, actions);
  }
}
