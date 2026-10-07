import 'package:flutter/material.dart';

import '../constants/demo_keys.dart';
import '../constants/demo_sizes.dart';
import '../constants/demo_strings.dart';
import 'theme_toggle_button.dart';
import 'top_bar_action.dart';

/// The demo's own controls, at the end of the top bar: Validate, Reset and
/// the light / dark toggle.
class TopBarActions extends StatelessWidget {
  /// Creates the controls.
  const TopBarActions({
    required this.themeMode,
    required this.onValidate,
    required this.onReset,
    required this.onThemeToggle,
    this.compact = false,
    super.key,
  });

  /// The theme in use, which the toggle shows.
  final ThemeMode themeMode;

  /// Validates the form shown.
  final VoidCallback onValidate;

  /// Mounts the form shown afresh.
  final VoidCallback onReset;

  /// Switches between the light and the dark theme.
  final VoidCallback onThemeToggle;

  /// Whether Validate and Reset show as icons, for a narrow window.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: compact ? 0 : DemoSizes.topBarGap,
      children: [
        TopBarAction(
          key: DemoKeys.validate,
          label: DemoStrings.validate,
          icon: Icons.fact_check_outlined,
          compact: compact,
          onPressed: onValidate,
        ),
        TopBarAction(
          key: DemoKeys.reset,
          label: DemoStrings.reset,
          icon: Icons.restart_alt,
          compact: compact,
          onPressed: onReset,
        ),
        ThemeToggleButton(themeMode: themeMode, onPressed: onThemeToggle),
      ],
    );
  }
}
