import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
final secureClientProvider = FutureProvider<SecureClient>((ref) {
  throw UnimplementedError(
    'secureClientProvider must be overridden in ProviderScope. '
    'See the doc comment for an example.',
  );
});
