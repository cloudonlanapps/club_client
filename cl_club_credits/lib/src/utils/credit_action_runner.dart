import 'package:cl_remote_store/cl_remote_store.dart' show writeFailureMessage;
import 'package:club_sdk_2/club_sdk_2.dart' show ServerException;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'credit_action_error.dart';

/// Runs one credit [action] for whatever hosts its form (club_core#101):
/// true once it succeeded; on a refusal, a toast with a fixed message and
/// false, so the form stays open for another try.
Future<bool> runCreditAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    return true;
  } on ServerException catch (e) {
    if (!context.mounted) return false;
    ShadToaster.of(context).show(
      ShadToast.destructive(description: Text(creditActionErrorMessage(e))),
    );
    return false;
  } on Object catch (e) {
    if (!context.mounted) return false;
    ShadToaster.of(context).show(
      ShadToast.destructive(
        description: Text(
          writeFailureMessage(e, fallback: creditActionSaveFailedMessage),
        ),
      ),
    );
    return false;
  }
}
