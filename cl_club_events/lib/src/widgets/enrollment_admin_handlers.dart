import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart'
    show
        EventType,
        ServerException,
        UserPrivate,
        canAssignTrial,
        mapEnrollmentMutationError;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../utils/event_write_error_message.dart';
import 'assign_trial_dialog.dart';
import 'conflict_breakdown_dialog.dart';
import 'user_selection_dialog.dart';

/// Shared assign/invite/assign-trial handlers used by both
/// `EventEnrolmentsView` and the inline pending-requests preview.

void showEnrollmentError(BuildContext context, Object e) {
  ShadToaster.of(context).show(
    ShadToast.destructive(
      description: Text(
        e is ServerException && !writeMayHaveLanded(e)
            ? mapEnrollmentMutationError(e)
            : eventWriteErrorMessage(e),
      ),
    ),
  );
}

/// Camp-only conflict pre-flight. Returns `true` to proceed.
Future<bool> maybeRunCampPreflight(
  BuildContext context,
  WidgetRef ref, {
  required int eventId,
  required List<String> usernames,
  required String title,
}) async {
  final event = ref.read(clEventsMasterProvider).valueOrNull?[eventId];
  if (event == null || event.type != EventType.camp) return true;

  try {
    final report = await ref
        .read(clEventsMasterProvider.notifier)
        .checkUserConflicts(eventId, usernames: usernames);
    if (!report.hasConflict) return true;

    if (!context.mounted) return false;
    final userList = ref.read(clUsersMasterProvider).valueOrNull;
    String? resolveName(String username) {
      final u = userList?[username];
      if (u == null) return null;
      return '${u.firstName} ${u.lastName}'.trim();
    }

    final proceed = await showConflictBreakdownDialog(
      context,
      report: report,
      title: title,
      displayNameResolver: resolveName,
    );
    return proceed ?? false;
  } on Object catch (e) {
    if (context.mounted) showEnrollmentError(context, e);
    return false;
  }
}

Future<void> handleAssignEnrollment(
  BuildContext context,
  WidgetRef ref, {
  required int eventId,
  required Set<String> excludeUsernames,
}) async {
  final selected = await showUserSelectionDialog(
    context,
    ref: ref,
    eventId: eventId,
    title: 'Assign Users',
    excludeUsernames: excludeUsernames,
    creditGated: true,
  );

  if (selected == null || selected.isEmpty) return;

  if (!context.mounted) return;
  final proceed = await maybeRunCampPreflight(
    context,
    ref,
    eventId: eventId,
    usernames: selected,
    title: 'Assign user conflicts',
  );
  if (!proceed) return;

  final notifier = ref.read(clEnrollmentsMasterProvider(eventId).notifier);
  try {
    if (selected.length == 1) {
      await notifier.assign(selected.first);
    } else {
      await notifier.assignBulk(selected);
    }
  } on Object catch (e) {
    if (context.mounted) showEnrollmentError(context, e);
  }
}

Future<void> handleInviteEnrollment(
  BuildContext context,
  WidgetRef ref, {
  required int eventId,
  required Set<String> excludeUsernames,
}) async {
  final selected = await showUserSelectionDialog(
    context,
    ref: ref,
    eventId: eventId,
    title: 'Invite Users',
    excludeUsernames: excludeUsernames,
  );

  if (selected == null || selected.isEmpty) return;

  if (!context.mounted) return;
  final proceed = await maybeRunCampPreflight(
    context,
    ref,
    eventId: eventId,
    usernames: selected,
    title: 'Invite user conflicts',
  );
  if (!proceed) return;

  final notifier = ref.read(clEnrollmentsMasterProvider(eventId).notifier);
  try {
    if (selected.length == 1) {
      await notifier.invite(selected.first);
    } else {
      await notifier.inviteBulk(selected);
    }
  } on Object catch (e) {
    if (context.mounted) showEnrollmentError(context, e);
  }
}

Future<void> handleAssignTrialEnrollment(
  BuildContext context,
  WidgetRef ref, {
  required int eventId,
  required UserPrivate actingUser,
  required Set<String> excludeUsernames,
}) async {
  final event = ref.read(clEventsMasterProvider).valueOrNull?[eventId];
  if (event == null) return;
  if (!canAssignTrial(event, actingUser)) return;

  final enrollments =
      ref.read(clEnrollmentsMasterProvider(eventId)).valueOrNull ?? {};

  final result = await showAssignTrialDialog(
    context,
    eventId: eventId,
    eventType: event.type,
    currentEnrollments: enrollments,
    excludeUsernames: excludeUsernames,
  );

  if (result == null) return;

  final notifier = ref.read(clEnrollmentsMasterProvider(eventId).notifier);
  try {
    await notifier.assignTrial(result.username);
  } on Object catch (e) {
    if (context.mounted) showEnrollmentError(context, e);
  }
}

/// Builds the excludeUsernames set (organizer + coaches) for a given event.
Set<String> excludeUsernamesForEvent(int eventId, WidgetRef ref) {
  final event = ref.read(clEventsMasterProvider).valueOrNull?[eventId];
  return <String>{
    if (event?.organizerName != null) event!.organizerName!,
    ...?event?.coachNames,
  };
}
