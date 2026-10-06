import 'package:cl_server_config/cl_server_config.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:club_sdk_2/remote_store.dart' show createRemotePublicSource;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The token-free `/public` surface (club_core#53), for the apps and the
/// website alike.
///
/// Nothing on `/public` needs a token, so this is built from the API base
/// alone rather than reached through the authenticated
/// `secureClientProvider`: the website holds no session, and an app's public
/// reads do not wait on one.
///
/// The one token-free read outside `/public`, `GET /capabilities`, is not
/// here: `capabilitiesProvider` serves it to the website through
/// `clSessionlessClientProvider` (club_core#31).
///
/// Internal: every public read goes through a provider in this package
/// (`clPublicEventsProvider`, `clPublicClubInfoProvider`, …). Tests override
/// it with a fake source.
final Provider<PublicSource> clPublicSourceProvider = Provider<PublicSource>((
  ref,
) {
  return createRemotePublicSource(baseUrl: ref.watch(apiBaseUrlProvider));
});
