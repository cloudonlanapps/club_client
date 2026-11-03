import 'package:cl_member_auth/cl_member_auth.dart' show canManageEnrollments;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEnrollmentRecordsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../enrollment_tile.dart';
import 'requests_display_name.dart';
import 'requests_empty.dart';

/// The Requests sheet's Enrollment or Withdrawal tab: the event's members
/// in [status], each an [EnrollmentTile]. Its Approve and Reject (with
/// their credit checks) show only to whoever may manage enrolment on the
/// event; an assigned coach reads the list (club_client#437).
class EnrollmentRequestsTab extends ConsumerWidget {
  const EnrollmentRequestsTab({
    required this.event,
    required this.actingUser,
    required this.status,
    required this.usernames,
    required this.emptyMessage,
    super.key,
  });

  final Event event;
  final UserPrivate actingUser;

  /// `requested` or `withdrawRequested`.
  final EnrollmentStatus status;

  /// The members in [status].
  final List<String> usernames;

  /// What the tab says when [usernames] is empty.
  final String emptyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (usernames.isEmpty) return RequestsEmpty(message: emptyMessage);
    final records = ref
        .watch(clEnrollmentRecordsMasterProvider(event.id))
        .valueOrNull;
    final canManage = canManageEnrollments(event, actingUser);
    return ListView(
      shrinkWrap: true,
      children: [
        for (final username in usernames)
          EnrollmentTile(
            key: ValueKey('request-$status-$username'),
            username: username,
            status: status,
            eventId: event.id,
            displayName: requestsDisplayName(ref, username),
            canManage: canManage,
            withdrawalReason: records?[username]?.withdrawalReason,
          ),
      ],
    );
  }
}
