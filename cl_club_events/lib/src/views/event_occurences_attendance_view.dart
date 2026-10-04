import 'dart:async';

import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show TitleRow;

import '../models/event_write_messages.dart';
import '../utils/attendance_roster_builder.dart';
import '../widgets/attendance_empty_roster.dart';
import '../widgets/attendance_layout_toggle.dart';
import '../widgets/attendance_roster_list.dart';
import '../widgets/attendance_window_banner.dart';
import '../widgets/pending_leaves_section.dart';

/// Attendance management widget for the
/// `/memberzone/events/:eventId/:occurrenceTimeUtc/attendance` route.
class EventOccurencesAttendanceView extends ConsumerStatefulWidget {
  const EventOccurencesAttendanceView({
    required this.currentUser,
    required this.eventId,
    required this.occurrenceTimeUtc,
    this.onBack,
    super.key,
  });

  final UserPrivate currentUser;
  final int eventId;
  final DateTime occurrenceTimeUtc;
  final VoidCallback? onBack;

  @override
  ConsumerState<EventOccurencesAttendanceView> createState() =>
      EventOccurencesAttendanceViewState();
}

class EventOccurencesAttendanceViewState
    extends ConsumerState<EventOccurencesAttendanceView> {
  /// Optimistic overrides for in-flight mutations: username -> the status shown
  /// while the mark/clear is applied to the server. A present key with a `null`
  /// value is an in-flight *clear*. Each entry is removed once its mutation
  /// settles, at which point the master provider holds the server truth.
  ///
  /// There is no Save step — every tap applies immediately (#726); this map
  /// exists only to keep the row responsive during the round trip and to revert
  /// cleanly on error.
  final Map<String, AttendanceStatus?> _pending = {};

  /// Roster layout. Default is a flat list sorted by name, so marking a member
  /// changes only that row in place. When true, members are grouped by
  /// attendance status (a marked member jumps to its status group).
  bool _groupByStatus = false;

  /// Members whose trial a mark on this session ended (club_core#98). They
  /// have left the programme; the register keeps them, flagged, until it is
  /// reopened.
  final Set<String> trialEnded = {};

  ClAttendancesKey get attendanceKey => (
    eventId: widget.eventId,
    occurrenceTimeUtc: widget.occurrenceTimeUtc,
  );

  /// Effective start of this occurrence — `OccurrenceOverride.newStartTimeUtc`
  /// when present, otherwise the slot key. Resolved via
  /// [clSingleOccurrenceProvider]; falls back to the slot key while loading
  /// or on error.
  /// Looks up the resolved occurrence (with overrides applied) via
  /// `clSingleOccurrenceProvider`. Falls back to the slot key for both
  /// start and end while loading.
  Occurrence? get _resolvedOccurrence => ref
      .watch(
        clSingleOccurrenceProvider((
          eventId: widget.eventId,
          occurrenceTimeUtc: widget.occurrenceTimeUtc,
        )),
      )
      .valueOrNull;

  DateTime get effectiveStartTimeUtc =>
      _resolvedOccurrence?.actualStartTimeUtc ?? widget.occurrenceTimeUtc;

  DateTime get effectiveEndTimeUtc =>
      _resolvedOccurrence?.actualEndTimeUtc ?? widget.occurrenceTimeUtc;

  bool get isWithinEditWindow {
    return DateTime.now().toUtc().difference(effectiveEndTimeUtc).inDays <=
        attendanceEditWindow.inDays;
  }

  bool get canMarkNow => canMarkAttendanceNow(
    actingUser: widget.currentUser,
    effectiveStartTimeUtc: effectiveStartTimeUtc,
    effectiveEndTimeUtc: effectiveEndTimeUtc,
  );

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final attendanceAsync = ref.watch(
      clAttendancesMasterProvider(attendanceKey),
    );
    final enrollmentsAsync = ref.watch(
      clEnrollmentRecordsMasterProvider(widget.eventId),
    );
    final eventMasterAsync = ref.watch(clEventsMasterProvider);
    final userListAsync = ref.watch(clUsersMasterProvider);

    final event = eventMasterAsync.whenOrNull(
      data: (master) => master[widget.eventId],
    );

    final userList = userListAsync.valueOrNull;

    String resolveDisplayName(String username) {
      final user = userList?[username];
      if (user != null) {
        return '${user.firstName} ${user.lastName}'.trim();
      }
      return username;
    }

    final opensAt = effectiveStartTimeUtc
        .subtract(attendanceOpenLeadIn)
        .toLocal();
    final canManage =
        event != null && canManageAttendance(event, widget.currentUser);
    // Rows are interactive only inside both windows; the banners above explain
    // why when they are not.
    final canEdit = canManage && canMarkNow && isWithinEditWindow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitleRow(
          title: event?.title ?? 'Event #${widget.eventId}',
          subtitle: 'Attendance',
          onBack: widget.onBack,
        ),
        const Divider(height: 1),
        if (!canMarkNow)
          AttendanceWindowBanner(
            icon: Icons.schedule,
            message:
                'Attendance opens 30 minutes before the session starts '
                '(opens $opensAt).',
          ),
        if (canMarkNow && !isWithinEditWindow)
          AttendanceWindowBanner(
            icon: Icons.info_outline,
            message:
                'Edit window closed. Attendance can only be edited within '
                '${attendanceEditWindow.inDays} days of the session.',
          ),
        Expanded(
          child: buildContent(
            theme,
            event,
            attendanceAsync,
            enrollmentsAsync,
            resolveDisplayName,
            canEdit: canEdit,
          ),
        ),
      ],
    );
  }

  Widget buildContent(
    ShadThemeData theme,
    Event? event,
    AsyncValue<List<AttendanceRecord>> attendanceAsync,
    AsyncValue<Map<String, Enrollment>> enrollmentsAsync,
    String Function(String) resolveDisplayName, {
    required bool canEdit,
  }) {
    final records = attendanceAsync.valueOrNull;
    final enrollments = enrollmentsAsync.valueOrNull;

    // Only block on the *first* load. After a mark/clear, the attendance
    // provider re-enters AsyncLoading while it refetches but keeps its previous
    // value — so we keep rendering the roster instead of flashing a full-page
    // spinner on every tap. The optimistic `_pending` override already shows
    // the tapped row's new state in the meantime.
    if (records == null || enrollments == null) {
      if (attendanceAsync.hasError) {
        return Center(
          child: Text(
            'Could not load attendance: ${attendanceAsync.error}',
            style: theme.textTheme.muted,
          ),
        );
      }
      if (enrollmentsAsync.hasError) {
        return Center(
          child: Text(
            'Could not load enrollments: ${enrollmentsAsync.error}',
            style: theme.textTheme.muted,
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    // A programme's credit roster, when credit is on, says who cannot be
    // charged (club_core#99); the provider makes no call otherwise.
    final creditRoster = ref
        .watch(clEventCreditRosterProvider(widget.eventId))
        .valueOrNull;
    final roster = buildAttendanceRoster(
      enrollments: enrollments,
      records: records,
      occurrenceTimeUtc: widget.occurrenceTimeUtc,
      creditRoster: creditRoster,
      trialEnded: trialEnded,
    );

    if (roster.isEmpty) return const AttendanceEmptyRoster();

    // Separate pending leaves from the main roster
    final pendingLeaves = roster
        .where((e) => e.currentStatus == AttendanceStatus.onLeaveRequested)
        .toList();
    final mainRoster = roster
        .where((e) => e.currentStatus != AttendanceStatus.onLeaveRequested)
        .toList();

    return Column(
      children: [
        AttendanceLayoutToggle(
          groupByStatus: _groupByStatus,
          onChanged: (value) => setState(() => _groupByStatus = value),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(clAttendancesMasterProvider(attendanceKey));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (pendingLeaves.isNotEmpty && event != null) ...[
                  PendingLeavesSection(
                    event: event,
                    pendingLeaves: pendingLeaves,
                    actingUser: widget.currentUser,
                    displayNameResolver: resolveDisplayName,
                    onApprove: (u) => unawaited(handleApproveLeave(u)),
                    onReject: (u) => unawaited(handleRejectLeave(u)),
                  ),
                  const SizedBox(height: 12),
                ],
                AttendanceRosterList(
                  entries: mainRoster,
                  groupByStatus: _groupByStatus,
                  pending: _pending,
                  onStatusChanged: (username, status) =>
                      unawaited(handleMark(username, status)),
                  onClear: (username) => unawaited(handleClear(username)),
                  onDisabledTap: (username) =>
                      handleDisabledTap(username, resolveDisplayName(username)),
                  displayNameResolver: resolveDisplayName,
                  isEditable: canEdit,
                  isSuperAdmin: widget.currentUser.isSuperAdmin,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  ClAttendancesMasterNotifier get attendance =>
      ref.read(clAttendancesMasterProvider(attendanceKey).notifier);

  /// Mark a single member, applied to the server immediately. The row shows
  /// the new status optimistically and reverts (with a toast) if the server
  /// rejects it. A mark that ends a trial flags the row (club_core#98); a
  /// refusal for lack of credit is toasted (club_core#99).
  Future<void> handleMark(String username, AttendanceStatus status) =>
      runPending(username, status, () async {
        final report = await attendance.markAttendance([
          AttendanceMarkRecord(membername: username, status: status),
        ]);
        if (!mounted) return;
        if (report.trialEnded.isNotEmpty) {
          setState(() => trialEnded.addAll(report.trialEnded));
        }
        if (report.refused.isNotEmpty) showRefused(report.refused);
      });

  /// Clear a single member's mark (optimistic, reverting on error). Reached
  /// by re-tapping the segment or the clear (✕) affordance.
  Future<void> handleClear(String username) =>
      runPending(username, null, () => attendance.clearAttendance(username));

  /// Runs one member's mark or clear with [status] shown optimistically
  /// meanwhile. Taps are ignored while that member's previous one is in
  /// flight.
  Future<void> runPending(
    String username,
    AttendanceStatus? status,
    Future<void> Function() call,
  ) async {
    if (_pending.containsKey(username)) return;
    setState(() => _pending[username] = status);
    try {
      await call();
    } on ServerException catch (e) {
      if (mounted) showToast(mapAttendanceMutationError(e), isError: true);
    } on Object catch (e) {
      if (mounted) {
        showToast(
          writeFailureMessage(e, fallback: attendanceSaveFailedMessage),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _pending.remove(username));
    }
  }

  /// Tapped a disabled toggle: the member is not enrolled for this occurrence
  /// and the viewer is not a super-admin.
  void handleDisabledTap(String username, String displayName) {
    showToast(
      '$displayName was not enrolled for this session — '
      'only a super-admin can mark them.',
    );
  }

  Future<void> handleApproveLeave(String username) => runLeaveDecision(
    () => attendance.approveLeave(username),
    'Leave approved for $username.',
  );

  Future<void> handleRejectLeave(String username) => runLeaveDecision(
    () => attendance.rejectLeave(username),
    'Leave rejected for $username.',
  );

  Future<void> runLeaveDecision(
    Future<void> Function() call,
    String done,
  ) async {
    try {
      await call();
      if (mounted) showToast(done);
    } on ServerException catch (e) {
      if (mounted) showToast(mapAttendanceMutationError(e), isError: true);
    } on Object catch (e) {
      if (mounted) {
        showToast(
          writeFailureMessage(e, fallback: leaveDecisionFailedMessage),
          isError: true,
        );
      }
    }
  }

  /// The server refused to charge these members (no credit left; the
  /// roster was a snapshot): coin and names, no prose (club_core#99).
  void showRefused(List<RefusedAttendance> refused) {
    ShadToaster.of(context).show(
      ShadToast.destructive(
        title: const Icon(LucideIcons.coins, size: 16),
        description: Text(refused.map((r) => r.membername).join(', ')),
      ),
    );
  }

  void showToast(String message, {bool isError = false}) {
    if (isError) {
      ShadToaster.of(
        context,
      ).show(ShadToast.destructive(description: Text(message)));
    } else {
      ShadToaster.of(context).show(ShadToast(description: Text(message)));
    }
  }
}
