import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/withdrawal_reasons.dart';

/// Single muted, italic line summarising the logged-in member's enrollment
/// status for an event.
///
/// Designed for use inside `EventCard`'s `extra` slot on the member dashboard.
/// Renders nothing while the enrollment fetch is loading or if the user has
/// no enrollment for this event.
class MyEnrollmentStatusLine extends ConsumerWidget {
  const MyEnrollmentStatusLine({
    required this.username,
    required this.eventId,
    required this.eventType,
    super.key,
  });

  final String username;
  final int eventId;
  final EventType eventType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final enrollment = ref
        .watch(clMyEnrollmentProvider((username: username, eventId: eventId)))
        .valueOrNull;
    if (enrollment == null) return const SizedBox.shrink();

    final style = theme.textTheme.small.copyWith(
      color: theme.colorScheme.mutedForeground,
      fontStyle: FontStyle.italic,
    );
    final trialDates = endedTrialDates(enrollment);
    if (trialDates != null) {
      // A trial that ended because its credit ran out: a flag and the
      // trial's dates, no prose (club_core#100).
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Semantics(
            label: 'Trial ended',
            child: Icon(
              LucideIcons.flag,
              size: 14,
              color: theme.colorScheme.mutedForeground,
            ),
          ),
          Text(trialDates, style: style),
        ],
      );
    }

    return Text(statusMessage(enrollment, eventType), style: style);
  }
}

/// The local dates of a trial that ended because its credit ran out
/// ("12 Sep – 23 Sep"), or null for any other enrollment. Told apart by the
/// server's reason code alone (club_core#100): an admin removing a trial
/// member is an ordinary removal.
String? endedTrialDates(Enrollment enrollment) {
  if (enrollment.status != EnrollmentStatus.removed ||
      !isTrialCreditExhausted(enrollment.withdrawalReason)) {
    return null;
  }
  final from = enrollment.enrolledAtUtc;
  final until = enrollment.withdrawnAtUtc;
  final format = DateFormat('d MMM');
  if (from == null || until == null) return '';
  return '${format.format(from.toLocal())} – ${format.format(until.toLocal())}';
}

/// The italic line for [enrollment]'s status.
String statusMessage(Enrollment enrollment, EventType eventType) {
  final status = enrollment.status;
  final typeName = switch (eventType) {
    EventType.programme => 'programme',
    EventType.camp => 'camp',
    EventType.oneOff => 'event',
  };
  return switch (status) {
    EnrollmentStatus.invited => 'You are invited to this $typeName',
    EnrollmentStatus.accepted => 'You have accepted this $typeName',
    EnrollmentStatus.assigned => 'You have been assigned for this $typeName',
    EnrollmentStatus.assignedTrial => 'You are on trial for this $typeName',
    EnrollmentStatus.requested => 'Request pending',
    EnrollmentStatus.withdrawRequested => 'Withdrawal pending',
    EnrollmentStatus.withdrawn => 'You have withdrawn',
    EnrollmentStatus.declined => 'You have declined',
    EnrollmentStatus.rejected => 'Your request was declined',
    EnrollmentStatus.removed => 'You have been removed',
  };
}
