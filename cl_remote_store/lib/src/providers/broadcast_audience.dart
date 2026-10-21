import 'package:cl_remote_store/src/models/broadcast_scope.dart';
import 'package:cl_remote_store/src/providers/enrollments_master.dart';
import 'package:cl_remote_store/src/providers/events_master.dart';
import 'package:cl_remote_store/src/providers/group_members.dart';
import 'package:cl_remote_store/src/providers/users_master.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enrolment statuses the server counts as an event's members for the
/// `event_members` audience (club_server `services/broadcast.py`).
const Set<EnrollmentStatus> _activeEnrollmentStatuses = {
  EnrollmentStatus.invited,
  EnrollmentStatus.requested,
  EnrollmentStatus.accepted,
  EnrollmentStatus.assigned,
  EnrollmentStatus.assignedTrial,
  EnrollmentStatus.withdrawRequested,
};

/// The usernames a Broadcast screen's **Staff only** switch sends to, as a
/// `users` audience (club_client#252):
///
/// * all members: every active coach and admin;
/// * a group: the group's members who are coaches or admins;
/// * an event: its own staff, the organizer and the coaches;
/// * a member: that member (the one-to-one screen has no Staff only).
///
/// The server's `role` audience takes one role and its `event_staff`
/// audience reaches the whole club's staff, so neither is used. Derived from
/// the users, events and group-members providers.
final AutoDisposeFutureProviderFamily<List<String>, BroadcastScope>
clBroadcastStaffProvider = FutureProvider.autoDispose
    .family<List<String>, BroadcastScope>((ref, scope) async {
      switch (scope.kind) {
        case BroadcastScopeKind.all:
          final users = await ref.watch(clUsersMasterProvider.future);
          return [
            for (final u in users.values)
              if (u.status == UserStatus.active && u.isCoachOrAdmin) u.username,
          ];
        case BroadcastScopeKind.group:
          final users = await ref.watch(clUsersMasterProvider.future);
          final members = await ref.watch(
            clGroupMembersProvider(scope.id!).future,
          );
          return [
            for (final m in members)
              if (users[m.membername]?.isCoachOrAdmin ?? false) m.membername,
          ];
        case BroadcastScopeKind.event:
          final events = await ref.watch(clEventsMasterProvider.future);
          final event = events[scope.id];
          if (event == null) return const [];
          return <String>{
            ?event.organizerName,
            ...?event.coachNames,
          }.toList();
        case BroadcastScopeKind.member:
          return [scope.username!];
      }
    });

/// The members a Broadcast screen's **Choose members** picker offers
/// (club_client#252): the screen's audience together with its staff
/// ([clBroadcastStaffProvider]), as the users master knows them.
///
/// * all members: every active member;
/// * a group: its members;
/// * an event: its enrolled members (the statuses the server's
///   `event_members` audience counts) and its staff;
/// * a member: that member.
final AutoDisposeFutureProviderFamily<List<UserInfo>, BroadcastScope>
clBroadcastMembersProvider = FutureProvider.autoDispose
    .family<List<UserInfo>, BroadcastScope>((ref, scope) async {
      final users = await ref.watch(clUsersMasterProvider.future);
      final Iterable<String> usernames;
      switch (scope.kind) {
        case BroadcastScopeKind.all:
          return [
            for (final u in users.values)
              if (u.status == UserStatus.active) u,
          ];
        case BroadcastScopeKind.group:
          final members = await ref.watch(
            clGroupMembersProvider(scope.id!).future,
          );
          usernames = members.map((m) => m.membername);
        case BroadcastScopeKind.event:
          final enrollments = await ref.watch(
            clEnrollmentsMasterProvider(scope.id!).future,
          );
          final staff = await ref.watch(clBroadcastStaffProvider(scope).future);
          usernames = {
            for (final e in enrollments.entries)
              if (_activeEnrollmentStatuses.contains(e.value)) e.key,
            ...staff,
          };
        case BroadcastScopeKind.member:
          usernames = [scope.username!];
      }
      return [
        for (final name in usernames)
          if (users[name] case final user?)
            if (user.status == UserStatus.active) user,
      ];
    });
