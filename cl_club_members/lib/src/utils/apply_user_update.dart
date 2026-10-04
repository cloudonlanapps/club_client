import 'package:cl_club_members/src/utils/profile_save_error_message.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClUsersMasterNotifier, clUserPrivateProvider, clUsersMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show ServerException;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Runs a partial-update call, invalidates the affected providers, and shows a
/// section-specific success toast (or an error toast). Returns `true` when the
/// update succeeded so the editor can leave edit mode.
Future<bool> applyUserUpdate(
  WidgetRef ref,
  BuildContext context,
  String username,
  Future<void> Function(ClUsersMasterNotifier notifier) update, {
  required String successMessage,
}) async {
  try {
    await update(ref.read(clUsersMasterProvider.notifier));
    ref
      ..invalidate(clUserPrivateProvider(username))
      ..invalidate(authStateProvider);
    if (!context.mounted) return true;
    ShadToaster.of(context).show(
      ShadToast(description: Text(successMessage)),
    );
    return true;
  } on ServerException catch (e) {
    if (!context.mounted) return false;
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
