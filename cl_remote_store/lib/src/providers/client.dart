import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/secure_client_not_provided.dart';

/// Authenticated [SecureClient] provider.
///
/// The host app **must** override this in its `ProviderScope` so that
/// data-fetching providers (coach list, organizer list, venue list) can
/// obtain the SDK client. The app gives it cl_member_auth's
/// `sessionClientProvider`, which waits while no one is signed in, so no
/// provider sends a request that needs the session after signing out
/// (club_client#272); the capabilities, which need none, are read through
/// `tokenFreeClientProvider` and the app's own client.
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     secureClientProvider.overrideWith(
///       (ref) => ref.watch(sessionClientProvider.future),
///     ),
///     tokenFreeClientProvider.overrideWith(
///       (ref) => ref.watch(clientProvider.future),
///     ),
///   ],
///   child: const MyApp(),
/// );
/// ```
///
/// Not overridden, it throws [SecureClientNotProvided]. The website, which
/// holds no session, leaves it so.
final secureClientProvider = FutureProvider<SecureClient>((ref) {
  throw const SecureClientNotProvided();
});
