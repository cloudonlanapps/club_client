import 'package:cl_club_branding/cl_club_branding.dart' show ThemeModeWidgetRef;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../l10n/site_strings.dart';

/// The size of the hero's action icons, matching the navbar's.
const double heroActionIconSize = 18;

/// The landing hero's top-right controls: the theme toggle and the menu.
///
/// No member-app icon: the menu this opens carries the Member Area
/// (club_core#184). The icon is for the desktop navbar, which has no menu.
///
/// The navbar fades in only once the visitor scrolls past half the hero, and
/// a club with no events has a page too short to get there; the menu button
/// keeps every page reachable from the hero itself (club_core#180). It opens
/// the shell's side menu, which every width carries.
class HeroTopActions extends ConsumerWidget {
  const HeroTopActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final isDark = ref.watchIsDark(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShadButton.ghost(
            size: ShadButtonSize.sm,
            onPressed: () => ref.toggleThemeMode(isDark: isDark),
            child: Icon(
              isDark ? LucideIcons.sun : LucideIcons.moon,
              size: heroActionIconSize,
            ),
          ),
          Semantics(
            button: true,
            label: SiteStrings.of(context).navMenu,
            excludeSemantics: true,
            child: ShadButton.ghost(
              size: ShadButtonSize.sm,
              onPressed: () => Scaffold.of(context).openEndDrawer(),
              child: const Icon(LucideIcons.menu, size: heroActionIconSize),
            ),
          ),
        ],
      ),
    );
  }
}
