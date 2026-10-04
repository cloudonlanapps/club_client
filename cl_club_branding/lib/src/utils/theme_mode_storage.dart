import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the viewer's light / dark choice is kept between runs.
///
/// A host reads it once before the first frame, with [load], and hands the
/// result to `initialThemeModeProvider`; `themeModeProvider` writes every
/// change back with [save].
abstract final class ThemeModeStorage {
  /// The SharedPreferences key holding the chosen [ThemeMode]'s name.
  static const String key = 'cl_club_branding.themeMode';

  /// The stored mode, or [ThemeMode.system] when none has been chosen.
  static Future<ThemeMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    return decode(prefs.getString(key));
  }

  /// Stores [mode] for the next start.
  static Future<void> save(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, mode.name);
  }

  /// The mode named [raw]; [ThemeMode.system] for null or an unknown name.
  static ThemeMode decode(String? raw) {
    for (final mode in ThemeMode.values) {
      if (mode.name == raw) return mode;
    }
    return ThemeMode.system;
  }
}
