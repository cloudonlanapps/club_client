import 'dart:async';

import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/event_write_messages.dart';
import '../../models/requests_tab.dart';
import '../leave_request_tile.dart';
import 'approved_leave_tile.dart';
import 'requests_display_name.dart';
import 'requests_empty.dart';

/// The Requests sheet's Leave tab (club_client#437): the session's pending
/// leave first, each with Approve and Reject for the event's staff
/// (`canManageAttendance`, an assigned coach included), then its approved
/// leave, to read. The server takes the decision before the session opens.
class LeaveRequestsTab extends ConsumerStatefulWidget {
  const LeaveRequestsTab({
    required this.event,
    required this.actingUser,
    required this.attendanceKey,
    required this.records,
    super.key,
  });

  final Event event;
  final UserPrivate actingUser;

  /// The session whose leave this is.
  final ClAttendancesKey attendanceKey;

  /// The session's records on leave or asking for it.
  final List<AttendanceRecord> records;

  @override
  ConsumerState<LeaveRequestsTab> createState() => LeaveRequestsTabState();
}

class LeaveRequestsTabState extends ConsumerState<LeaveRequestsTab> {
  /// Members whose decision is in flight.
  final Set<String> processing = {};

  @override
  Widget build(BuildContext context) {
    final pending = [
      for (final r in widget.records)
        if (r.status == AttendanceStatus.onLeaveRequested) r,
    ];
    final approved = [
      for (final r in widget.records)
        if (r.status == AttendanceStatus.onLeave) r,
    ];
    if (pending.isEmpty && approved.isEmpty) {
      return RequestsEmpty(message: RequestsTab.leave.emptyMessage);
    }
    final muted = ShadTheme.of(context).textTheme.muted;
    return ListView(
      shrinkWrap: true,
      children: [
        for (final r in pending)
          LeaveRequestTile(
            key: ValueKey('leave-pending-${r.membername}'),
            username: r.membername,
            displayName: requestsDisplayName(ref, r.membername),
            event: widget.event,
            actingUser: widget.actingUser,
            leaveReason: r.leaveReason,
            isProcessing: processing.contains(r.membername),
            onApprove: () => unawaited(decide(r.membername, approve: true)),
            onReject: () => unawaited(decide(r.membername, approve: false)),
          ),
        if (approved.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
            child: Text(approvedLeaveHeading, style: muted),
          ),
          for (final r in approved)
            ApprovedLeaveTile(
              key: ValueKey('leave-approved-${r.membername}'),
              displayName: requestsDisplayName(ref, r.membername),
              leaveReason: r.leaveReason,
            ),
        ],
      ],
    );
  }

  /// Approves or rejects [username]'s leave; the list reloads from the
  /// master, and a refusal is toasted.
  Future<void> decide(String username, {required bool approve}) async {
    if (processing.contains(username)) return;
    setState(() => processing.add(username));
    final toaster = ShadToaster.of(context);
    final master = ref.read(
      clAttendancesMasterProvider(widget.attendanceKey).notifier,
    );
    try {
      await (approve
          ? master.approveLeave(username)
          : master.rejectLeave(username));
      toaster.show(
        ShadToast(
          description: Text(
            'Leave ${approve ? 'approved' : 'rejected'} for '
            '${requestsDisplayName(ref, username)}.',
          ),
        ),
      );
    } on ServerException catch (e) {
      toaster.show(
        ShadToast.destructive(description: Text(mapAttendanceMutationError(e))),
      );
    } on Object catch (e) {
      toaster.show(
        ShadToast.destructive(
          description: Text(
            writeFailureMessage(e, fallback: leaveDecisionFailedMessage),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => processing.remove(username));
    }
  }
}

/// The heading over the Leave tab's approved leave.
const String approvedLeaveHeading = 'Approved';
