import 'package:cl_club_members/src/utils/profile_save_error_message.dart';
import 'package:cl_club_members/src/utils/sync_signed_in_user.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClUsersMasterNotifier, clUsersMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show ServerException, UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Runs a partial-update call, hands the saved user to the session when it is
/// the signed-in user ([syncSignedInUser]), and shows a section-specific
/// success toast (or an error toast). Returns `true` when the
/// update succeeded so the editor can leave edit mode.
///
/// A section whose form can show a server refusal on the field it names
/// passes [onRefused]: it returns true once it has shown the refusal there,
/// and no toast follows.
Future<bool> applyUserUpdate(
  WidgetRef ref,
  BuildContext context,
  String username,
  Future<UserPrivate> Function(ClUsersMasterNotifier notifier) update, {
  required String successMessage,
  bool Function(ServerException error)? onRefused,
}) async {
  try {
    final updated = await update(ref.read(clUsersMasterProvider.notifier));
    syncSignedInUser(ref, updated);
    if (!context.mounted) return true;
    ShadToaster.of(context).show(
      ShadToast(description: Text(successMessage)),
    );
    return true;
  } on ServerException catch (e) {
    if (!context.mounted) return false;
    if (onRefused?.call(e) ?? false) return false;
    ShadToaster.of(context).show(
      ShadToast.destructive(description: Text(profileSaveErrorMessage(e))),
    );
    return false;
  } on Object catch (_) {
    if (!context.mounted) return false;
    ShadToaster.of(context).show(
      const ShadToast.destructive(
        description: Text('Could not save. Please try again.'),
      ),
    );
    return false;
  }
}
