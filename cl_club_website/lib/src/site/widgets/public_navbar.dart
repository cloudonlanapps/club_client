import 'package:cl_club_branding/cl_club_branding.dart' show ThemeModeWidgetRef;
import 'package:cl_club_website/cl_club_website.dart'
    show ClubLogo, SiteStrings, routeLabel;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'member_app_button.dart';

/// Responsive width helper - returns max content width based on screen size
double getMaxContentWidth(double screenWidth) {
  if (screenWidth < 1000) return double.infinity; // Mobile/Tablet: full width
  if (screenWidth < 1280) return 1140; // Small desktop
  if (screenWidth < 1536) return 1320; // Large desktop
  return 1440; // Extra large
}

/// Shared navbar used by both landing page and public pages
class PublicNavbar extends ConsumerWidget {
  const PublicNavbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final strings = SiteStrings.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 1000;
    final maxWidth = getMaxContentWidth(screenWidth);
    final isDark = ref.watchIsDark(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.border),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo - left-aligned within the constrained box
                GestureDetector(
                  onTap: () => context.go(
                    '/',
                    extra: DateTime.now().millisecondsSinceEpoch,
                  ),
                  child: const ClubLogo(height: 40),
                ),

                // Navigation (Desktop) or Menu (Mobile)
                if (!isMobile)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      NavLink(label: strings.navHome, path: '/'),
                      NavLink(
                        label: routeLabel(strings, 'events')!,
                        path: '/public/events',
                      ),
                      NavLink(
                        label: routeLabel(strings, 'programs')!,
                        path: '/public/programs',
                      ),
                      NavLink(
                        label: routeLabel(strings, 'one-off')!,
                        path: '/public/one-off',
                      ),
                      NavLink(
                        label: routeLabel(strings, 'coaches')!,
                        path: '/public/coaches',
                      ),
                      NavLink(
                        label: routeLabel(strings, 'rinks')!,
                        path: '/public/rinks',
                      ),
                      NavLink(
                        label: routeLabel(strings, 'about-us')!,
                        path: '/public/about-us',
                      ),
                      const SizedBox(width: 8),
                      ShadButton.ghost(
                        size: ShadButtonSize.sm,
                        onPressed: () => ref.toggleThemeMode(isDark: isDark),
                        child: Icon(
                          isDark ? LucideIcons.sun : LucideIcons.moon,
                          size: 18,
                        ),
                      ),
                      const MemberAppButton(),
                    ],
                  )
                else
                  Row(
                    children: [
                      ShadButton.ghost(
                        size: ShadButtonSize.sm,
                        onPressed: () => ref.toggleThemeMode(isDark: isDark),
                        child: Icon(
                          isDark ? LucideIcons.sun : LucideIcons.moon,
                          size: 18,
                        ),
                      ),
                      ShadButton.ghost(
                        size: ShadButtonSize.sm,
                        onPressed: () => Scaffold.of(context).openEndDrawer(),
                        child: const Icon(LucideIcons.menu),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NavLink extends StatelessWidget {
  const NavLink({required this.label, required this.path, super.key});
  final String label;
  final String path;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ShadButton.ghost(
        size: ShadButtonSize.sm,
        onPressed: () {
          final currentPath = GoRouterState.of(context).uri.toString();
          if (currentPath == path) return; // Already on this page
          if (path == '/') {
            context.go('/', extra: DateTime.now().millisecondsSinceEpoch);
          } else {
            context.go(path);
          }
        },
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.small.copyWith(
            height: 1.3,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
