import 'dart:async';

import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth.dart';
import 'client.dart';

/// The SDK client for requests that need a signed-in member.
///
/// While someone is signed in it is the [clientProvider] client. While no
/// one is — before a sign-in, while a session is being restored, and from
/// the moment of signing out — it is a future that never completes, so a
/// provider that waits on it sends nothing and keeps the value it had
/// (club_client#272). Signing in again hands every waiting provider the
/// new client.
///
/// The host app gives it to `secureClientProvider` (cl_remote_store), which
/// every master provider reads. A read the server answers without a session
/// (`GET /capabilities`) goes through `tokenFreeClientProvider` instead.
final sessionClientProvider = FutureProvider<SecureClient>((ref) {
  final signedIn = ref.watch(
    authStateProvider.select((auth) => auth.valueOrNull != null),
  );
  if (!signedIn) return Completer<SecureClient>().future;
  return ref.watch(clientProvider.future);
});
