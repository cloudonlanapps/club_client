import 'package:shadcn_ui/shadcn_ui.dart';

/// The ghost-button theme both integrators use.
///
/// The stock ghost variant draws in `colorScheme.primary`; this draws icon
/// buttons, nav links and back buttons in the neutral `foreground`, keeping
/// the brand colour for primary actions. `ShadThemeData` merges the partial
/// override with the variant's defaults, so every other ghost-button
/// property is kept.
ShadButtonTheme neutralGhostButton(ShadColorScheme scheme) {
  return ShadButtonTheme(
    foregroundColor: scheme.foreground,
    hoverForegroundColor: scheme.accentForeground,
  );
}
