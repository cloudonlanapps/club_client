import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'token_storage.dart';

/// HTTP headers to send when fetching authenticated image URLs.
///
/// Returns `{'Authorization': 'Bearer <token>'}` when a session is present,
/// or an empty map when logged out. Image widgets that point at protected
/// endpoints (e.g. `/v1/media/by_id/<uuid>/download` for non-public media)
/// pass the result to `cached_network_image`'s `httpHeaders` parameter.
///
/// Currently public endpoints simply ignore the extra header, so the same
/// widget keeps working before and after the server protects the endpoint.
final imageAuthHeadersProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  final storage = ref.watch(tokenStorageProvider);
  final session = await storage.read();
  final token = session?.accessToken;
  if (token == null || token.isEmpty) return const {};
  return {'Authorization': 'Bearer $token'};
});
