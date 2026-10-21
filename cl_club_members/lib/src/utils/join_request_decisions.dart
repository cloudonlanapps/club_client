import 'package:cl_club_members/src/utils/member_write_messages.dart';
import 'package:cl_club_members/src/views/group_join_requests_view.dart'
    show RejectReasonDialog, kRejectCancelled;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        ClGroupRequestsMasterNotifier,
        clGroupRequestsMasterProvider,
        clMyJoinRequestsMasterProvider,
        writeFailureMessage;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Approves join request [requestId] on group [groupId] and says so in a
/// toast. [onBusy] is called with `true` when the call starts and `false`
/// when it ends, for the host's in-flight state. Returns whether it was
/// approved.
///
/// The one approve flow every join-request host uses (club_client#226).
Future<bool> approveJoinRequest(
  BuildContext context, {
  required int groupId,
  required int requestId,
  required ValueChanged<bool> onBusy,
}) {
  return _decide(
    context,
    groupId: groupId,
    onBusy: onBusy,
    decide: (master) => master.approve(requestId),
    success: 'Request approved.',
    refusal: _approveRefusal,
    fallback: MemberWriteMessages.approveRequestFailed,
  );
}

/// Asks for a reason, then rejects join request [requestId] on group
/// [groupId] and says so in a toast. Cancelling the reason dialog does
/// nothing. [onBusy] is as for [approveJoinRequest]. Returns whether it was
/// rejected.
Future<bool> rejectJoinRequest(
  BuildContext context, {
  required int groupId,
  required int requestId,
  required ValueChanged<bool> onBusy,
}) async {
  final reason = await showShadDialog<String?>(
    context: context,
    builder: (_) => const RejectReasonDialog(),
  );
  if (reason == kRejectCancelled || !context.mounted) return false;
  final trimmed = reason?.trim();
  return _decide(
    context,
    groupId: groupId,
    onBusy: onBusy,
    decide: (master) => master.reject(
      requestId,
      reason: trimmed == null || trimmed.isEmpty ? null : trimmed,
    ),
    success: 'Request rejected.',
    refusal: (e) => 'Could not reject: ${e.message}',
    fallback: MemberWriteMessages.rejectRequestFailed,
  );
}

Future<bool> _decide(
  BuildContext context, {
  required int groupId,
  required ValueChanged<bool> onBusy,
  required Future<JoinRequest> Function(ClGroupRequestsMasterNotifier master)
  decide,
  required String success,
  required String Function(ServerException e) refusal,
  required String fallback,
}) async {
  // Read up front: the host may be gone by the time the server answers.
  final container = ProviderScope.containerOf(context, listen: false);
  final master = container.read(
    clGroupRequestsMasterProvider(groupId).notifier,
  );
  final toaster = ShadToaster.of(context);
  onBusy(true);
  try {
    final decided = await decide(master);
    // The requester's own list of requests is not the group master's to
    // refresh.
    container.invalidate(clMyJoinRequestsMasterProvider(decided.username));
    toaster.show(ShadToast(description: Text(success)));
    return true;
  } on ServerException catch (e) {
    toaster.show(ShadToast.destructive(description: Text(refusal(e))));
    return false;
  } on Object catch (e) {
    toaster.show(
      ShadToast.destructive(
        description: Text(writeFailureMessage(e, fallback: fallback)),
      ),
    );
    return false;
  } finally {
    if (context.mounted) onBusy(false);
  }
}

String _approveRefusal(ServerException e) {
  switch (e.code) {
    case SdkErrorCode.notEligible:
      return 'No longer eligible for this group.';
    case SdkErrorCode.alreadyMember:
      return 'User is already a member.';
    default:
      return 'Could not approve: ${e.message}';
  }
}
