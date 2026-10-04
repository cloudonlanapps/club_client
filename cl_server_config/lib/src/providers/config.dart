import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/server_config.dart';

/// Provider for the server configuration.
///
/// The host app **must** override this in its `ProviderScope`:
///
/// ```dart
/// runApp(ProviderScope(
///   overrides: [
///     serverConfigProvider.overrideWithValue(
///       const ServerConfig(baseUrl: 'https://api.example.com/v1'),
///     ),
///   ],
///   child: const MyApp(),
/// ));
/// ```
final serverConfigProvider = Provider<ServerConfig>((ref) {
  throw UnimplementedError(
    'serverConfigProvider must be overridden in ProviderScope. '
    'See ServerConfig docs for an example.',
  );
});

/// The API base URL, derived from [serverConfigProvider].
///
/// Convenience provider so consumers can watch a simple `String` instead
/// of the full [ServerConfig] object.
final apiBaseUrlProvider = Provider<String>((ref) {
  return ref.watch(serverConfigProvider).baseUrl;
});
