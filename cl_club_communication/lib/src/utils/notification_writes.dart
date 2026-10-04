import 'package:cl_remote_store/cl_remote_store.dart'
    show clNotificationsMasterProvider, writeFailureMessage;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Shown when marking a notification read fails.
const String markReadFailedMessage = 'Could not mark the notification as read.';

/// Shown when marking every notification read fails.
const String markAllReadFailedMessage =
    'Could not mark the notifications as read. Please try again.';

/// Marks notification [id] read, then calls [open]. A failed mark is toasted
/// with fixed text and the notification still opens (club_core#138).
Future<void> markReadThenOpen(
  BuildContext context,
  WidgetRef ref,
  int id,
  VoidCallback open,
) async {
  try {
    await ref.read(clNotificationsMasterProvider.notifier).markRead(id);
  } on Object catch (e) {
    if (context.mounted) showWriteFailure(context, e, markReadFailedMessage);
  }
  open();
}

/// Marks every loaded notification read; a failure is toasted with fixed
/// text (club_core#138).
Future<void> markAllReadReporting(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(clNotificationsMasterProvider.notifier).markAllRead();
  } on Object catch (e) {
    if (context.mounted) showWriteFailure(context, e, markAllReadFailedMessage);
  }
}

/// Toasts a failed notification write: [fallback], or that the change is
/// unconfirmed when it may have landed. Never the raw error.
void showWriteFailure(BuildContext context, Object error, String fallback) {
  ShadToaster.of(context).show(
    ShadToast.destructive(
      description: Text(writeFailureMessage(error, fallback: fallback)),
    ),
  );
}
