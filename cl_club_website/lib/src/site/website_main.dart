import 'package:cl_club_branding/cl_club_branding.dart'
    show ThemeModeStorage, initialThemeModeProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show bundledContactInfoProvider;
import 'package:cl_server_config/cl_server_config.dart'
    show ServerConfig, serverConfigProvider;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:media_kit/media_kit.dart';

import '../models/site_config.dart';
import '../providers/member_app_uri.dart';
import 'app.dart';

/// Starts a club website.
///
/// A site's `main.dart` is exactly `void main() => websiteMain();`. What
/// differs between clubs is in the host's assets, at the paths the club apps
/// use: `assets/club.json`, `assets/images/club_logo.png` and
/// `assets/data/contact_info.json`, plus the site's own
/// `assets/l10n/app_en.arb`, `assets/config/theme.json` and bundled media.
///
/// The config, contact block and remembered theme mode are read before the
/// first frame, as `clubMain` does; the copy loads behind
/// `siteStringsProvider`.
Future<void> websiteMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  usePathUrlStrategy();

  final (config, contact, themeMode) = await (
    SiteConfig.load(),
    loadBundledContactInfo(),
    ThemeModeStorage.load(),
  ).wait;
  if (kDebugMode) print('[websiteMain] starting ${config.fullName}');

  runApp(
    ProviderScope(
      overrides: [
        siteConfigProvider.overrideWithValue(config),
        serverConfigProvider.overrideWithValue(
          ServerConfig(
            baseUrl: _apiBaseUrlOverride.isNotEmpty
                ? _apiBaseUrlOverride
                : config.apiBaseUrl,
          ),
        ),
        bundledContactInfoProvider.overrideWithValue(contact),
        initialThemeModeProvider.overrideWithValue(themeMode),
        memberAppUriProvider.overrideWithValue(
          switch (_memberAppUrlOverride.isNotEmpty
              ? _memberAppUrlOverride
              : config.memberAppUrl) {
            final String url => Uri.parse(url),
            null => null,
          },
        ),
      ],
      child: const App(),
    ),
  );
}

/// `--dart-define=CLUB_API_BASE_URL=...` points a build at another server
/// than `club.json` names, as it does for `clubMain`.
const _apiBaseUrlOverride = String.fromEnvironment('CLUB_API_BASE_URL');

/// `--dart-define=CLUB_MEMBER_APP_URL=...` names the environment's member
/// app, overriding `club.json`'s `memberAppUrl`; the deploy passes it.
const _memberAppUrlOverride = String.fromEnvironment('CLUB_MEMBER_APP_URL');
