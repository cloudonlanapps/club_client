// What to expect from the stack under test, and how to skip what does not
// apply to it.
//
// The suite runs once per server conf (app_test_server1.conf,
// app_test_server2.conf at the club_core root), and the confs differ in the
// optional modules and in identity verification. A test decides what to
// expect from `GET /v1/capabilities`, never from which club is running, and
// a case that does not apply to this stack reports as skipped with a reason,
// not as a pass that asserted nothing.

import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:club_sdk_2/remote_store.dart' show createRemoteSecureClient;
import 'package:flutter_test/flutter_test.dart';

/// Reads the stack's capabilities as [username]. `GET /capabilities` needs an
/// authenticated caller, so pass the sudo credentials a test already has.
/// Call once, from `setUpAll`.
Future<Capabilities> stackCapabilities({
  required String baseUrl,
  required String username,
  required String password,
}) async {
  final client = await createRemoteSecureClient(baseUrl: baseUrl);
  await client.auth.login(username, password);
  try {
    return await client.capabilities.getCapabilities();
  } finally {
    await client.auth.logout();
  }
}

/// Marks the running test skipped and returns true when [enabled] is false,
/// so a body can open with:
///
/// ```dart
/// if (skipUnless(enabled: caps.creditSystem, feature: 'credit system')) {
///   return;
/// }
/// ```
bool skipUnless({required bool enabled, required String feature}) {
  if (enabled) return false;
  markTestSkipped('$feature is off on this stack');
  return true;
}

/// The counterpart of [skipUnless], for a case that only exists while a
/// feature is **off**: marks the running test skipped and returns true when
/// [enabled] is true.
bool skipIf({required bool enabled, required String feature}) {
  if (!enabled) return false;
  markTestSkipped('$feature is on on this stack');
  return true;
}

/// Marks the running test skipped at a known, open issue (a failure, or a
/// gap in the app the test cannot get past), citing the
/// club_core issue that tracks it, and returns true. Everything the test
/// asserted up to this point still ran. Call it where the failure would
/// start:
///
/// ```dart
/// if (skipKnownFailure(issue: 107, what: 'My Calendar misses one-offs')) {
///   await logout(tester);
///   return;
/// }
/// ```
///
/// Where only one assertion is wrong and the rest of the test does not
/// depend on it, call it as a statement in that assertion's place instead:
/// the test goes on, and is still reported failed if anything later fails.
///
/// Remove the call and its block when [issue] is fixed.
bool skipKnownFailure({required int issue, required String what}) {
  markTestSkipped('known issue, club_core#$issue: $what');
  return true;
}
