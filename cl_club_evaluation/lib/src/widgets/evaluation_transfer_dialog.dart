import 'package:cl_remote_store/cl_remote_store.dart'
    show clUsersMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show EvaluationStaffView, UserStatus;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart' show PickerUser, showUserSelectionDialog;

import '../constants/evaluation_view_strings.dart';

/// Picks the coach to hand [evaluation] to — any active coach but its
/// effective owner and the member it is about; resolves to the username,
/// or `null` when cancelled.
Future<String?> showEvaluationTransferDialog(
  BuildContext context,
  WidgetRef ref,
  EvaluationStaffView evaluation,
) async {
  final users = await ref.read(clUsersMasterProvider.future);
  if (!context.mounted) return null;
  final coaches = [
    for (final u in users.values)
      if (u.roles.isCoach &&
          u.status == UserStatus.active &&
          u.username != evaluation.effectiveOwner &&
          u.username != evaluation.createdFor)
        PickerUser(
          username: u.username,
          displayName: u.displayName,
          firstName: u.firstName,
          lastName: u.lastName,
          nickname: u.nickname,
          isCoach: true,
        ),
  ]..sort((a, b) => a.displayName.compareTo(b.displayName));
  final picked = await showUserSelectionDialog(
    context,
    title: EvaluationViewStrings.transferTo,
    users: coaches,
    confirmLabel: EvaluationViewStrings.transfer,
    emptyText: EvaluationViewStrings.noCoaches,
    showRoleFilter: false,
    singleSelect: true,
  );
  return picked == null || picked.isEmpty ? null : picked.single;
}
