import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart';

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
/// Hosts the resolved actions and hands them to [builder] as a typed
/// `List<ActionItem>` — the caller wraps them into an [EntityCard] via
/// `trailingActions:`. The list is empty when the acting user is not on
/// the event's staff or no enrollments callback is wired.
class AdminEventActions extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final actingUser = ref.watch(authStateProvider).valueOrNull;
    final actions = <ActionItem>[
      if (actingUser != null &&
          canManageAttendance(event, actingUser) &&
          onEnrollments != null)
        ActionItem(label: 'Enrollments', onPressed: onEnrollments),
    ];
    return builder(context, actions);
  }
}
