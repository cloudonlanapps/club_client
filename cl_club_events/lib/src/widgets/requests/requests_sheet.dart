import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/requests_tab.dart';
import 'enrollment_requests_tab.dart';
import 'leave_requests_tab.dart';

/// The Requests sheet's title.
const String requestsSheetTitle = 'Requests';

/// The widest the Requests sheet grows on a large screen.
const double requestsSheetMaxWidth = 520;

/// Opens the Requests sheet of [occurrence] (club_client#437), reloading
/// the event's enrolments and the session's attendance first so the tabs
/// show what the server holds now.
Future<void> showRequestsSheet(
  BuildContext context,
  WidgetRef ref, {
  required Occurrence occurrence,
}) {
  ref
    ..invalidate(clEnrollmentsMasterProvider(occurrence.eventId))
    ..invalidate(clEnrollmentRecordsMasterProvider(occurrence.eventId))
    ..invalidate(clAttendancesMasterProvider(requestsLeaveKey(occurrence)));
  return showShadSheet<void>(
    context: context,
    side: ShadSheetSide.right,
    builder: (_) => RequestsSheet(occurrence: occurrence),
  );
}

/// The attendance key of [occurrence]'s leave: its original slot.
ClAttendancesKey requestsLeaveKey(Occurrence occurrence) => (
  eventId: occurrence.eventId,
  occurrenceTimeUtc: occurrence.originalStartTimeUtc,
);

/// A session's open requests in three tabs, Leave first: the session's
/// leave, and the event's enrolment and withdrawal requests. Each tab's
/// label carries its count. Who may decide what is the tabs' concern.
class RequestsSheet extends ConsumerWidget {
  const RequestsSheet({required this.occurrence, super.key});

  final Occurrence occurrence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actingUser = ref.watch(authStateProvider).valueOrNull;
    final event = ref
        .watch(clEventsMasterProvider)
        .valueOrNull?[occurrence.eventId];
    final records = ref.watch(
      clAttendancesMasterProvider(requestsLeaveKey(occurrence)),
    );
    final enrollments = ref.watch(
      clEnrollmentsMasterProvider(occurrence.eventId),
    );
    final size = MediaQuery.sizeOf(context);

    final leave = [
      for (final r in records.valueOrNull ?? const <AttendanceRecord>[])
        if (r.status == AttendanceStatus.onLeaveRequested ||
            r.status == AttendanceStatus.onLeave)
          r,
    ];
    List<String> withStatus(EnrollmentStatus status) => [
      for (final e in (enrollments.valueOrNull ?? const {}).entries)
        if (e.value == status) e.key,
    ];
    final joining = withStatus(EnrollmentStatus.requested);
    final leaving = withStatus(EnrollmentStatus.withdrawRequested);

    Widget body(AsyncValue<Object> source, Widget Function() content) =>
        source.hasValue
        ? content()
        : source.hasError
        ? Center(child: Text(source.error.toString()))
        : const Center(child: CircularProgressIndicator());

    return ShadSheet(
      title: const Text(requestsSheetTitle),
      scrollable: false,
      constraints: BoxConstraints(
        maxWidth: size.width < requestsSheetMaxWidth
            ? size.width
            : requestsSheetMaxWidth,
      ),
      child: SizedBox(
        height: size.height * 0.8,
        child: actingUser == null || event == null
            ? const Center(child: CircularProgressIndicator())
            : ShadTabs<RequestsTab>(
                value: RequestsTab.leave,
                // Three labels with counts outgrow a phone's width.
                scrollable: true,
                tabs: [
                  ShadTab(
                    value: RequestsTab.leave,
                    expandContent: true,
                    content: body(
                      records,
                      () => LeaveRequestsTab(
                        event: event,
                        actingUser: actingUser,
                        attendanceKey: requestsLeaveKey(occurrence),
                        records: leave,
                      ),
                    ),
                    child: Text(RequestsTab.leave.labelWith(leave.length)),
                  ),
                  for (final (tab, usernames, status) in [
                    (
                      RequestsTab.enrollment,
                      joining,
                      EnrollmentStatus.requested,
                    ),
                    (
                      RequestsTab.withdrawal,
                      leaving,
                      EnrollmentStatus.withdrawRequested,
                    ),
                  ])
                    ShadTab(
                      value: tab,
                      expandContent: true,
                      content: body(
                        enrollments,
                        () => EnrollmentRequestsTab(
                          event: event,
                          actingUser: actingUser,
                          status: status,
                          usernames: usernames,
                          emptyMessage: tab.emptyMessage,
                        ),
                      ),
                      child: Text(tab.labelWith(usernames.length)),
                    ),
                ],
              ),
      ),
    );
  }
}
