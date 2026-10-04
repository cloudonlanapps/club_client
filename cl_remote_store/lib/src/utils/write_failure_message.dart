import 'package:cl_remote_store/src/utils/uncertain_write.dart';

/// Shown when a write failed in a way that may still have reached the
/// server: the master has reloaded, so the screen shows what the server
/// holds (club_core#138).
const String uncertainWriteMessage =
    'The server did not confirm this change. The screen has been refreshed: '
    'check whether it was saved before trying again.';

/// The message for a failed write: [uncertainWriteMessage] when the write
/// may have landed ([writeMayHaveLanded]), otherwise the caller's fixed
/// [fallback]. Never the raw error.
String writeFailureMessage(Object error, {required String fallback}) =>
    writeMayHaveLanded(error) ? uncertainWriteMessage : fallback;
