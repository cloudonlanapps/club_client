import 'package:club_sdk_2/club_sdk_2.dart';

/// Lowest HTTP status of a server-side failure.
const int serverErrorStatus = 500;

/// Whether a write that failed with [error] may still have been applied.
///
/// From club_sdk 0.6.0 a POST, PATCH, PUT or DELETE is not retried: it fails
/// on the first 5xx, timeout or dropped connection, and in each of those the
/// server may already have done the work (club_core#138). A 4xx refusal is
/// a definite "not done", and a client-side [SdkException] was never sent.
/// Anything else — a timeout, a connection failure, an unexpected error —
/// leaves the outcome unknown.
bool writeMayHaveLanded(Object error) {
  if (error is ServerException) return error.statusCode >= serverErrorStatus;
  if (error is SdkException) return false;
  return true;
}

/// Runs [write]; when it fails in a way that may have reached the server
/// ([writeMayHaveLanded]), calls [refetch] so the affected state reloads
/// from the server, then rethrows the error unchanged for the caller to
/// report.
///
/// A write that landed then shows up after the refetch, instead of the
/// screen inviting a duplicate retry.
Future<T> refetchIfWriteUncertain<T>(
  Future<T> Function() write, {
  required void Function() refetch,
}) async {
  try {
    return await write();
  } on Object catch (error) {
    if (writeMayHaveLanded(error)) refetch();
    rethrow;
  }
}
