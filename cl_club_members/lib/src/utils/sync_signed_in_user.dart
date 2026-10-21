import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// After a profile save: when [updated] is the signed-in user, it replaces
/// the user held by `authStateProvider`; anyone else's save changes nothing
/// about the session (club_client#231). The session is never restored again
/// for a save: the server's answer is the new user.
void syncSignedInUser(WidgetRef ref, UserPrivate updated) {
  final signedIn = ref.read(authStateProvider).valueOrNull;
  if (signedIn == null || signedIn.username != updated.username) return;
  ref.read(authStateProvider.notifier).setUser(updated);
}
