import 'package:cl_remote_store/cl_remote_store.dart'
    show clUsersMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart' show PickerUser, showUserSelectionDialog;

/// The picker entry of [username]: its names and roles from [master], or the
/// username alone when the master does not hold it.
PickerUser eventStaffPickerFor(String username, Map<String, UserInfo>? master) {
  final info = master?[username];
  if (info == null) {
    return PickerUser(username: username, displayName: username);
  }
  return PickerUser(
    username: username,
    displayName: info.displayName,
    firstName: info.firstName,
    lastName: info.lastName,
    nickname: info.nickname,
    isAdmin: info.roles.isAdmin,
    isCoach: info.roles.isCoach,
  );
}

/// The members of [master] an event's staff picker offers: those [where]
/// accepts, less the super admins and the usernames in [exclude], by
/// display name.
List<PickerUser> eventStaffCandidates(
  Map<String, UserInfo> master, {
  required bool Function(UserInfo) where,
  Set<String> exclude = const {},
}) {
  final list =
      master.entries
          .where(
            (e) =>
                !e.value.isSuperAdmin &&
                where(e.value) &&
                !exclude.contains(e.key),
          )
          .map((e) => eventStaffPickerFor(e.key, master))
          .toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
  return list;
}

/// Asks for an event's organizer, an admin or a coach, in the user picker.
/// Resolves to the member picked, or `null` when none was.
Future<PickerUser?> pickEventOrganizer(
  BuildContext context,
  WidgetRef ref,
) async {
  final master = await ref.read(clUsersMasterProvider.future);
  if (!context.mounted) return null;
  final candidates = eventStaffCandidates(
    master,
    where: (u) => u.roles.isAdmin || u.roles.isCoach,
  );
  final picked = await showUserSelectionDialog(
    context,
    title: 'Transfer organizer',
    description: 'Organizer must be an admin or a coach.',
    users: candidates,
    confirmLabel: 'Transfer',
    showRoleFilter: false,
    singleSelect: true,
  );
  if (picked == null || picked.isEmpty) return null;
  return candidates.firstWhere((c) => c.username == picked.first);
}

/// Asks for coaches to add to an event in the user picker, leaving out the
/// usernames in [exclude]. Resolves to the coaches picked, or `null` when
/// the picker was dismissed.
Future<List<PickerUser>?> pickEventCoaches(
  BuildContext context,
  WidgetRef ref,
  Set<String> exclude,
) async {
  final master = await ref.read(clUsersMasterProvider.future);
  if (!context.mounted) return null;
  final candidates = eventStaffCandidates(
    master,
    where: (u) => u.roles.isCoach,
    exclude: exclude,
  );
  final picked = await showUserSelectionDialog(
    context,
    title: 'Add coaches',
    users: candidates,
    confirmLabel: 'Add',
    emptyText: 'No more coaches to add.',
    showRoleFilter: false,
  );
  if (picked == null) return null;
  final set = picked.toSet();
  return candidates.where((c) => set.contains(c.username)).toList();
}
