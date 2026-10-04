import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/theme_mode_storage.dart';
import 'initial_theme_mode.dart';

/// The light / dark mode the club app or site is shown in.
///
/// Starts from [initialThemeModeProvider] and remembers every change through
/// [ThemeModeStorage], so the choice survives a restart. Widgets read it
/// through the `WidgetRef` helpers `watchIsDark` and `toggleThemeMode`.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Holds the current [ThemeMode] and persists changes to it.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(initialThemeModeProvider);

  /// Shows [mode] and stores it for the next start.
  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ThemeModeStorage.save(mode);
  }

  /// Switches to the opposite of what is on screen: light when [isDark],
  /// dark otherwise. A viewer following the system leaves it on the first
  /// toggle.
  Future<void> toggle({required bool isDark}) =>
      set(isDark ? ThemeMode.light : ThemeMode.dark);
}
