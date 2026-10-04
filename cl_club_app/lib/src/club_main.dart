import 'package:cl_club_branding/cl_club_branding.dart'
    show
        ThemeModeStorage,
        appBrandingProvider,
        appLogoUriProvider,
        initialThemeModeProvider;
import 'package:cl_member_auth/cl_member_auth.dart'
    show authStateProvider, clientProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        bundledContactInfoProvider,
        clubEventTypesProvider,
        currentUserProvider,
        secureClientProvider;
import 'package:cl_server_config/cl_server_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:media_kit/media_kit.dart';

import 'app.dart';
import 'models/bundled_contact_info.dart';
import 'models/club_config.dart';
import 'providers/public_site_uri.dart';
import 'utils/configured_uri.dart';

/// Starts a club app.
///
/// Every club's `main.dart` is exactly `Future<void> main() => clubMain();` —
/// no arguments, because the config and assets live at conventional paths that
/// this function knows. What differs between clubs is entirely in
/// `assets/club.json` and the two asset files beside it.
///
/// A build-time `--dart-define` still overrides the API URL, so a dev build can
/// be pointed at a local server without editing the config that ships, and
/// another overrides the website URL, which differs between environments.
Future<void> clubMain({List<Override> extraOverrides = const []}) async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  usePathUrlStrategy();

  final (config, themeMode, contact) = await (
    ClubConfig.load(),
    ThemeModeStorage.load(),
    loadBundledContactInfo(),
  ).wait;
  if (kDebugMode) print('[clubMain] starting ${config.fullName}');

  runApp(
    ProviderScope(
      overrides: [
        clubConfigProvider.overrideWithValue(config),
        initialThemeModeProvider.overrideWithValue(themeMode),
        serverConfigProvider.overrideWithValue(
          ServerConfig(
            baseUrl: _apiBaseUrlOverride.isNotEmpty
                ? _apiBaseUrlOverride
                : config.apiBaseUrl,
          ),
        ),
        appLogoUriProvider.overrideWithValue(
          Uri.parse('asset:$kClubLogoAsset'),
        ),
        appBrandingProvider.overrideWithValue(config.branding),
        clubEventTypesProvider.overrideWithValue(config.eventTypes),
        bundledContactInfoProvider.overrideWithValue(contact),
        publicSiteUriProvider.overrideWithValue(
          configuredUri(
            override: _publicSiteUrlOverride,
            configured: config.websiteUrl,
          ),
        ),
        secureClientProvider.overrideWith(
          (ref) => ref.watch(clientProvider.future),
        ),
        currentUserProvider.overrideWith(
          (ref) => ref.watch(authStateProvider).valueOrNull,
        ),
        ...extraOverrides,
      ],
      child: const App(),
    ),
  );
}

/// The running club's configuration.
///
/// Always overridden by [clubMain]; the default throws rather than inventing
/// values, because a club app that reached this would be misconfigured in a way
/// worth failing on.
final clubConfigProvider = Provider<ClubConfig>((ref) {
  throw StateError(
    'clubConfigProvider was read without being overridden. It is supplied by '
    'clubMain(); a widget test needs to override it explicitly.',
  );
});

/// Overrides the API base URL for this build, e.g. to point at a dev server.
/// Empty means "use whatever the club config says".
const _apiBaseUrlOverride = String.fromEnvironment('CLUB_API_BASE_URL');

/// Overrides `club.json`'s `websiteUrl` for this build: the deploy passes the
/// environment's website. Empty means "use whatever the club config says".
const _publicSiteUrlOverride = String.fromEnvironment('CLUB_PUBLIC_SITE_URL');
