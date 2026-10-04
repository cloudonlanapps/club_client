import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'client.dart';

/// Result of an inline username-availability check.
enum UsernameAvailability {
  /// The username can be registered.
  available,

  /// The username is already taken.
  taken,
}

/// Public, unauthenticated check against `/auth/username-available`.
///
/// Family-keyed by the username being probed. Auto-disposes so a busy
/// signup form does not retain results for every keystroke. The caller
/// is expected to debounce input (~400ms) before watching this provider,
/// otherwise every keystroke fires its own HTTP call.
///
/// Returns [UsernameAvailability.available] / [UsernameAvailability.taken].
/// Network and validation failures bubble up as `AsyncError` so the
/// caller can decide how to surface them.
final AutoDisposeFutureProviderFamily<UsernameAvailability, String>
usernameAvailabilityProvider = FutureProvider.autoDispose
    .family<UsernameAvailability, String>(
      (ref, username) async {
        final client = await ref.watch(clientProvider.future);
        final available = await client.auth.isUsernameAvailable(username);
        return available
            ? UsernameAvailability.available
            : UsernameAvailability.taken;
      },
    );
