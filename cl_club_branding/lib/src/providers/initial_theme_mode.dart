import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The theme mode to start in: the viewer's remembered choice.
///
/// The host reads it before the first frame and overrides this, so the first
/// frame is already in the remembered mode:
///
/// ```dart
/// initialThemeModeProvider.overrideWithValue(await ThemeModeStorage.load()),
/// ```
///
/// Left alone it follows the system, which is also what a viewer who has
/// never chosen gets.
final initialThemeModeProvider = Provider<ThemeMode>(
  (ref) => ThemeMode.system,
);
