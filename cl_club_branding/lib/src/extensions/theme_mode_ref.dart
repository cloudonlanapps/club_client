import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_mode.dart';
import '../utils/is_dark_theme.dart';

/// The two things a theme toggle needs from [themeModeProvider].
extension ThemeModeWidgetRef on WidgetRef {
  /// Whether the page is dark right now, rebuilding when the mode or (under
  /// [ThemeMode.system]) the platform brightness changes.
  bool watchIsDark(BuildContext context) => isDarkTheme(
    watch(themeModeProvider),
    MediaQuery.platformBrightnessOf(context),
  );

  /// Switches to the opposite of [isDark] — the value [watchIsDark] gave the
  /// toggle — and remembers the choice.
  void toggleThemeMode({required bool isDark}) {
    unawaited(read(themeModeProvider.notifier).toggle(isDark: isDark));
  }
}
