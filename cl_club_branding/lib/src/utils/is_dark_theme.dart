import 'package:flutter/material.dart';

/// Whether [mode] renders dark on a platform currently in
/// [platformBrightness]: [ThemeMode.system] follows the platform, the other
/// modes ignore it.
bool isDarkTheme(ThemeMode mode, Brightness platformBrightness) =>
    switch (mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => platformBrightness == Brightness.dark,
    };
