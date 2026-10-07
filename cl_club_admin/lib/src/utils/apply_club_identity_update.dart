import 'package:cl_remote_store/cl_remote_store.dart'
    show ClClubIdentityMasterNotifier, clClubIdentityMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show ClubIdentity, ServerException;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/club_identity_messages.dart';

/// Runs one section's [update] of the club's identity and says how it went.
/// Returns `true` when it was stored, so the editor can leave edit mode.
///
/// Stored: a toast with [successMessage]. Refused by the server: [onRefused]
/// gets a fixed message to put back on the form (`showErrors`); the server
/// checks the document as a whole and names no field. Any other failure: a
/// toast with the same message.
Future<bool> applyClubIdentityUpdate({
  required WidgetRef ref,
  required BuildContext context,
  required Future<ClubIdentity> Function(ClClubIdentityMasterNotifier notifier)
  update,
  required String successMessage,
  required ValueChanged<String> onRefused,
}) async {
  final toaster = ShadToaster.of(context);
  try {
    await update(ref.read(clClubIdentityMasterProvider.notifier));
    toaster.show(ShadToast(description: Text(successMessage)));
    return true;
  } on ServerException catch (_) {
    onRefused(ClubIdentityMessages.saveFailed);
    return false;
  } on Object catch (_) {
    toaster.show(
      const ShadToast.destructive(
        description: Text(ClubIdentityMessages.saveFailed),
      ),
    );
    return false;
  }
}
