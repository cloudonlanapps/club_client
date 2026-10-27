import 'package:cl_club_branding/cl_club_branding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show ScrollSafeTapOutside, darkCustomColors, lightCustomColors;

import 'club_main.dart' show clubConfigProvider;
import 'router.dart';

/// The browser tab's title: `<shortName> Member App`, the name the app
/// installs under (#367).
String memberAppTitle(ClubBranding branding) =>
    [branding.shortName, 'Member App'].where((s) => s.isNotEmpty).join(' ');

/// The club app: the router under the club's theme, in the remembered
/// light / dark mode.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final branding = ref.watch(appBrandingProvider);

    final colorSource = ClubColorSource(
      schemeName: ref.watch(clubConfigProvider).themeColorName,
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

    return ScrollSafeTapOutside(
      child: ShadApp.router(
        routerConfig: router,
        title: memberAppTitle(branding),
        themeMode: themeMode,
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
