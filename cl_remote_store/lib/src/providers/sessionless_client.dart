import 'package:cl_server_config/cl_server_config.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:club_sdk_2/remote_store.dart' show createRemoteSecureClient;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A logged-out SDK client built from the API base alone (club_core#31), for
/// the few routes outside `/public` that need no token.
///
/// Building it only constructs objects: no token is read or stored, nothing
/// is refreshed and no request is sent until a caller makes one. It never
/// logs in, so the website still holds no session.
///
/// Internal: `capabilitiesProvider` reads `GET /capabilities` through it
/// when the host gave no `secureClientProvider` (the website). Nothing else
/// should; `/public` reads go through `clPublicSourceProvider`. Tests
/// override it with a fake client.
final FutureProvider<SecureClient> clSessionlessClientProvider =
    FutureProvider<SecureClient>((ref) {
      return createRemoteSecureClient(baseUrl: ref.watch(apiBaseUrlProvider));
    });
