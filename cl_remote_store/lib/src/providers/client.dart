import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/secure_client_not_provided.dart';

/// Authenticated [SecureClient] provider.
///
/// The host app **must** override this in its `ProviderScope` so that
/// data-fetching providers (coach list, organizer list, venue list) can
/// obtain the SDK client.
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     secureClientProvider.overrideWith(
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
