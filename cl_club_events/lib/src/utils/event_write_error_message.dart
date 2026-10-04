import 'package:cl_remote_store/cl_remote_store.dart' show writeFailureMessage;
import 'package:club_sdk_2/club_sdk_2.dart' show SdkError;

import '../models/event_write_messages.dart';

/// The toast for an event write that failed with something other than a
/// server refusal the caller maps itself (club_core#138).
///
/// A client-side [SdkError] — the eligibility pre-check before an approval
/// or invite — carries its own member-facing reason. Anything else says the
/// change is unconfirmed when it may have landed, or [fallback]; never the
/// raw error.
String eventWriteErrorMessage(
  Object error, {
  String fallback = eventActionFailedMessage,
}) {
  if (error is SdkError) return error.message;
  return writeFailureMessage(error, fallback: fallback);
}
