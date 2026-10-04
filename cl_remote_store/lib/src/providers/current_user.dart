import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Current logged-in user, injected by the host app.
///
/// The host app **must** override this in its `ProviderScope` so that
/// master providers can adjust fetch strategy based on the user's role.
///
/// ```dart
/// ProviderScope(
///   overrides: [
///     currentUserProvider.overrideWith(
///       (ref) => ref.watch(authStateProvider).valueOrNull,
///     ),
///   ],
///   child: const MyApp(),
/// );
/// ```
final currentUserProvider = Provider<UserInfo?>((ref) {
  throw UnimplementedError(
    'currentUserProvider must be overridden in ProviderScope. '
    'See the doc comment for an example.',
  );
});
