import 'package:cl_club_branding/cl_club_branding.dart'
    show buildClubColorScheme, neutralGhostButton, themeModeProvider;
import 'package:cl_club_website/cl_club_website.dart'
    show SiteStringsGate, WebsiteShellConfig, siteConfigProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show darkCustomColors, lightCustomColors;

import '../providers/page_meta.dart';
import 'router.dart';
import 'theme/theme_config.dart';
import 'theme/theme_config_provider.dart';
import 'widgets/public_navbar.dart';

/// Root app widget.
///
/// Always renders [ShadApp.router] with the [routerProvider] mounted, so the
/// browser URL (and any deep link such as `/public/events/6`) is parsed by
/// GoRouter on first frame. While the asset-driven [ThemeConfig] is still
/// loading, [ThemeConfig.defaultColorSource] is used; the real theme swaps in
/// once the async value resolves.
///
/// IMPORTANT: We must NOT replace the router shell with a non-router
/// `MaterialApp` while the theme loads — doing so caused deep links to fall
/// back to `initialLocation: '/'` because the URL was being processed before
/// the router existed.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeConfigAsync = ref.watch(themeConfigProvider);

    // The page on screen names itself (PageMetaPublisher): its title is the
    // browser's, and its description goes where a search engine reads it.
    final pageMeta = ref.watch(pageMetaProvider);
    ref.listen(pageMetaProvider, (previous, next) {
      if (previous?.description != next?.description) {
        ref.read(pageDescriptionWriterProvider)(next?.description);
      }
    });

    // Use the loaded config when available; fall back to the default while
    // the async asset is still loading or if it errored out. The router stays
    // mounted across both states so deep links are preserved.
    final colorSource = themeConfigAsync.maybeWhen(
      data: (config) => config.toColorSource(),
      orElse: () => ThemeConfig.defaultColorSource,
    );

    final lightColorScheme = buildClubColorScheme(
      brightness: Brightness.light,
      source: colorSource,
      customColors: lightCustomColors,
    );
    final darkColorScheme = buildClubColorScheme(
      brightness: Brightness.dark,
      source: colorSource,
      customColors: darkCustomColors,
    );

    return WebsiteShellConfig(
      navbarBuilder: (context) => const PublicNavbar(),
      child: ShadApp.router(
        routerConfig: router,
        title: pageMeta?.title ?? ref.watch(siteConfigProvider).fullName,
        themeMode: themeMode,
        // Every page waits for the site's copy (siteStringsProvider) and
        // reads it from the scope this puts above the navigator.
        builder: (context, child) => SiteStringsGate(child: child!),
        theme: ShadThemeData(
          brightness: Brightness.light,
          colorScheme: lightColorScheme,
          ghostButtonTheme: neutralGhostButton(lightColorScheme),
        ),
        darkTheme: ShadThemeData(
          brightness: Brightness.dark,
          colorScheme: darkColorScheme,
          ghostButtonTheme: neutralGhostButton(darkColorScheme),
        ),
      ),
    );
  }
}
