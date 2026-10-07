import 'package:cl_club_branding/cl_club_branding.dart' show AppLogo;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show AvatarCircleVariant;

import 'nav_item.dart';
import 'sidebar_item.dart';

export 'nav_item.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    required this.currentUser,
    required this.onNavigate,
    this.pathPrefix = '',
    this.isCollapsed = false,
    this.onLogoTap,
    this.eventTypes = const {EventType.camp},
    this.evaluations = false,
    this.unhandledInquiries = 0,
    super.key,
  });

  final UserInfo currentUser;

  /// Open website inquiries, shown as a count on the admin Inquiries entry.
  final int unhandledInquiries;

  /// The event types the club runs; each gets its staff list entry.
  final Set<EventType> eventTypes;

  /// Whether the server runs evaluations (`evaluationsProvider` is `true`):
  /// then every member gets *Reviews* under Main and staff get *Reviews*
  /// under Club Management (club_core#174). Unknown counts as off.
  final bool evaluations;

  final String pathPrefix;
  final bool isCollapsed;

  /// Navigates to the given (already prefix-resolved) path. The host owns
  /// navigation; the sidebar never calls the router directly.
  final ValueChanged<String> onNavigate;

  /// Optional callback fired when the brand header (logo + name text)
  /// is tapped. Hooked up by the host to navigate to `/memberzone/contact`.
  final VoidCallback? onLogoTap;

  bool get isAdmin => currentUser.roles.isAdmin || currentUser.isSuperAdmin;
  bool get isCoach => currentUser.roles.isCoach;

  /// Computes a display label from the user's staff roles; a user with
  /// none is a plain member.
  String get roleLabel {
    if (currentUser.isSuperAdmin) return 'Super Admin';
    if (currentUser.roles.isAdmin && currentUser.roles.isCoach) {
      return 'Admin / Coach';
    }
    if (currentUser.roles.isAdmin) return 'Admin';
    if (currentUser.roles.isCoach) return 'Coach';
    return 'Member';
  }

  List<NavItem> get allItems => [
    const NavItem(
      icon: LucideIcons.layoutDashboard,
      label: 'Dashboard',
      path: '/',
      section: 'Main',
    ),
    NavItem(
      icon: LucideIcons.calendarDays,
      label: 'Calendar',
      path: '/my-events/${currentUser.username}/calendar',
      section: 'Main',
    ),
    NavItem(
      icon: LucideIcons.users,
      label: 'Groups',
      path: '/my-groups/${currentUser.username}',
      section: 'Main',
    ),
    NavItem(
      icon: LucideIcons.calendarHeart,
      label: 'Events',
      path: '/my-events/${currentUser.username}',
      section: 'Main',
    ),
    NavItem(
      icon: LucideIcons.clipboardCheck,
      label: 'Attendance',
      path: '/my-events/${currentUser.username}/attendance',
      section: 'Main',
    ),
    if (evaluations)
      const NavItem(
        icon: LucideIcons.clipboardList,
        label: 'Reviews',
        path: '/reviews/mine',
        section: 'Main',
      ),
    const NavItem(
      icon: LucideIcons.calendar,
      label: 'Club Calendar',
      path: '/events/calendar',
      section: 'Club Management',
      coachOrAdmin: true,
    ),
    const NavItem(
      icon: LucideIcons.users,
      label: 'Members',
      path: '/users',
      section: 'Club Management',
      coachOrAdmin: true,
    ),
    const NavItem(
      icon: LucideIcons.mapPin,
      label: 'Venues',
      path: '/venues',
      section: 'Club Management',
      coachOrAdmin: true,
    ),
    const NavItem(
      icon: LucideIcons.usersRound,
      label: 'Groups',
      path: '/groups',
      section: 'Club Management',
      coachOrAdmin: true,
    ),
    if (eventTypes.contains(EventType.programme))
      const NavItem(
        icon: LucideIcons.trophy,
        label: 'Programmes',
        path: '/events/programmes',
        section: 'Club Management',
        coachOrAdmin: true,
      ),
    if (eventTypes.contains(EventType.camp))
      const NavItem(
        icon: LucideIcons.tent,
        label: 'Camps',
        path: '/events/camps',
        section: 'Club Management',
        coachOrAdmin: true,
      ),
    if (eventTypes.contains(EventType.oneOff))
      const NavItem(
        icon: LucideIcons.calendarCheck,
        label: 'One-off Events',
        path: '/events/one-off',
        section: 'Club Management',
        coachOrAdmin: true,
      ),
    if (evaluations)
      const NavItem(
        icon: LucideIcons.clipboardPen,
        label: 'Reviews',
        path: '/reviews',
        section: 'Club Management',
        coachOrAdmin: true,
      ),
    NavItem(
      icon: LucideIcons.inbox,
      label: 'Inquiries',
      path: '/inquiries',
      section: 'Admin',
      adminOnly: true,
      badgeCount: unhandledInquiries,
    ),
    const NavItem(
      icon: LucideIcons.image,
      label: 'Website media',
      path: '/site-media',
      section: 'Admin',
      superAdminOnly: true,
    ),
    const NavItem(
      icon: LucideIcons.building,
      label: 'Club details',
      path: '/club-details',
      section: 'Admin',
      superAdminOnly: true,
    ),
    const NavItem(
      icon: LucideIcons.user,
      label: 'Profile',
      path: '/profile',
      section: 'Account',
    ),
    const NavItem(
      icon: LucideIcons.messageCircle,
      label: 'Contact us',
      path: '/contact',
      section: 'Account',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final visibleItems = allItems
        .where(
          (item) => item.isVisibleFor(
            isAdmin: isAdmin,
            isCoach: isCoach,
            isSuperAdmin: currentUser.isSuperAdmin,
          ),
        )
        .toList();
    final currentLocation = GoRouterState.of(context).matchedLocation;

    return Container(
      width: isCollapsed ? 72 : 240,
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        border: Border(
          right: BorderSide(color: theme.colorScheme.border),
        ),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onLogoTap,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCollapsed ? 14 : 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: theme.colorScheme.border),
                  ),
                ),
                child: Center(
                  child: AppLogo(height: isCollapsed ? 44 : 96),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isCollapsed ? 14 : 8,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: isCollapsed
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: buildNavItems(
                    context,
                    visibleItems,
                    theme,
                    currentLocation,
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(isCollapsed ? 14 : 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.colorScheme.border),
                ),
              ),
              child: Row(
                children: [
                  AvatarCircleVariant(
                    name: currentUser.displayName,
                    size: 34,
                    color: theme.colorScheme.primary,
                  ),
                  if (!isCollapsed) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentUser.displayName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            currentUser.username,
                            style: theme.textTheme.muted.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> buildNavItems(
    BuildContext context,
    List<NavItem> visibleItems,
    ShadThemeData theme,
    String currentLocation,
  ) {
    final widgets = <Widget>[];
    String? lastSection;

    final allPaths = visibleItems
        .map(
          (i) => i.path == '/'
              ? (pathPrefix.isEmpty ? '/' : pathPrefix)
              : '$pathPrefix${i.path}',
        )
        .toList();

    for (final item in visibleItems) {
      if (item.section != null && item.section != lastSection) {
        if (lastSection != null) {
          widgets.add(const SizedBox(height: 8));
        }
        if (!isCollapsed) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Text(
                item.section!.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.mutedForeground,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          );
        }
        lastSection = item.section;
      }

      final badge = item.badgeCount;

      final effectivePath = item.path == '/'
          ? (pathPrefix.isEmpty ? '/' : pathPrefix)
          : '$pathPrefix${item.path}';

      final isSelected = effectivePath == '/'
          ? currentLocation == '/'
          : currentLocation == effectivePath ||
                (currentLocation.startsWith('$effectivePath/') &&
                    !allPaths.any(
                      (p) =>
                          p != effectivePath &&
                          p != '/' &&
                          p.startsWith('$effectivePath/') &&
                          (currentLocation == p ||
                              currentLocation.startsWith('$p/')),
                    ));

      widgets.add(
        SidebarItem(
          icon: item.icon,
          label: item.label,
          isSelected: isSelected,
          isCollapsed: isCollapsed,
          badgeCount: badge,
          highlightBackground: item.path != '/',
          onTap: () {
            final scaffold = Scaffold.maybeOf(context);
            if (scaffold != null && scaffold.isDrawerOpen) {
              Navigator.of(context).pop();
            }
            onNavigate(effectivePath);
          },
        ),
      );
    }

    return widgets;
  }
}
