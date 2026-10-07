import 'package:flutter/material.dart';

import '../constants/demo_keys.dart';
import '../constants/demo_strings.dart';

/// The light / dark toggle of the top bar.
class ThemeToggleButton extends StatelessWidget {
  /// Creates the toggle.
  const ThemeToggleButton({
    required this.themeMode,
    required this.onPressed,
    super.key,
  });

  /// The theme in use.
  final ThemeMode themeMode;

  /// Switches the theme.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: DemoKeys.themeToggle,
      tooltip: DemoStrings.toggleTheme,
      icon: Icon(
        themeMode == ThemeMode.light
            ? Icons.dark_mode_outlined
            : Icons.light_mode_outlined,
      ),
      onPressed: onPressed,
    );
  }
}
