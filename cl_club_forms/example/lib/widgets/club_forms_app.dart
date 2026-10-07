import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/demo_strings.dart';
import 'forms_shell.dart';

/// The demo: a preview of every form of `cl_club_forms`, picked from a
/// sidebar, in a light or a dark theme.
class ClubFormsApp extends StatefulWidget {
  /// Creates the app.
  const ClubFormsApp({super.key});

  @override
  State<ClubFormsApp> createState() => ClubFormsAppState();
}

/// State of [ClubFormsApp]: the theme in use.
class ClubFormsAppState extends State<ClubFormsApp> {
  /// The theme in use.
  ThemeMode themeMode = ThemeMode.light;

  /// Switches between the light and the dark theme.
  void toggleTheme() {
    setState(() {
      themeMode = themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      title: DemoStrings.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: const ShadBlueColorScheme.light(),
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadBlueColorScheme.dark(),
      ),
      home: FormsShell(themeMode: themeMode, onThemeToggle: toggleTheme),
    );
  }
}
