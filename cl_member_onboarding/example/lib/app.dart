import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show darkCustomColors, lightCustomColors;

import 'screens/onboarding_demo_shell.dart';

class MemberOnboardingExampleApp extends StatefulWidget {
  const MemberOnboardingExampleApp({super.key});

  @override
  State<MemberOnboardingExampleApp> createState() =>
      _MemberOnboardingExampleAppState();
}

class _MemberOnboardingExampleAppState
    extends State<MemberOnboardingExampleApp> {
  ThemeMode themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      themeMode = themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lightColorScheme = _buildColorScheme(
      brightness: Brightness.light,
      customColors: lightCustomColors,
    );
    final darkColorScheme = _buildColorScheme(
      brightness: Brightness.dark,
      customColors: darkCustomColors,
    );

    return ShadApp(
      title: 'Member Onboarding Example',
      themeMode: themeMode,
      theme: ShadThemeData(
        brightness: Brightness.light,
        colorScheme: lightColorScheme,
        ghostButtonTheme: _neutralGhostButton(lightColorScheme),
      ),
      darkTheme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: darkColorScheme,
        ghostButtonTheme: _neutralGhostButton(darkColorScheme),
      ),
      home: Scaffold(
        body: OnboardingDemoShell(
          onThemeToggle: toggleTheme,
          themeMode: themeMode,
        ),
      ),
    );
  }
}

ShadButtonTheme _neutralGhostButton(ShadColorScheme scheme) {
  return ShadButtonTheme(
    foregroundColor: scheme.foreground,
    hoverForegroundColor: scheme.accentForeground,
  );
}

ShadColorScheme _buildColorScheme({
  required Brightness brightness,
  required Map<String, Color> customColors,
}) {
  final base = ShadColorScheme.fromName('orange', brightness: brightness);
  return base.copyWith(custom: customColors);
}
