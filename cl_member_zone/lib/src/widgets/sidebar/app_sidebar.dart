import 'package:cl_club_branding/cl_club_branding.dart' show AppLogo;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show AvatarCircleVariant;

import 'nav_item.dart';
import 'sidebar_destination.dart';
import 'sidebar_item.dart';

export 'nav_item.dart';
export 'sidebar_destination.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    required this.currentUser,
    required this.onNavigate,
    required this.routeFor,
    required this.currentLocation,
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

  final bool isCollapsed;

  /// The route of each entry, from the host's router.
  final SidebarRoute routeFor;

  /// The location the app is at, from the host's router; the entry it falls
  /// under is highlighted.
  final String currentLocation;

  /// Navigates to an entry's route (from [routeFor]). The host owns
  /// navigation; the sidebar never calls the router directly.
  final ValueChanged<String> onNavigate;

  /// Optional callback fired when the brand header (logo + name text)
  /// is tapped. Hooked up by the host to open the contact page.
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
      destination: SidebarDestination.dashboard,
      section: 'Main',
    ),
    const NavItem(
      icon: LucideIcons.calendarDays,
      label: 'Calendar',
      destination: SidebarDestination.myCalendar,
      section: 'Main',
    ),
    const NavItem(
      icon: LucideIcons.users,
      label: 'Groups',
      destination: SidebarDestination.myGroups,
      section: 'Main',
    ),
    const NavItem(
      icon: LucideIcons.calendarHeart,
      label: 'Events',
      destination: SidebarDestination.myEvents,
      section: 'Main',
    ),
    const NavItem(
      icon: LucideIcons.clipboardCheck,
      label: 'Attendance',
      destination: SidebarDestination.myAttendance,
      section: 'Main',
    ),
    if (evaluations)
      const NavItem(
        icon: LucideIcons.clipboardList,
        label: 'Reviews',
        destination: SidebarDestination.myReviews,
        section: 'Main',
      ),
    const NavItem(
      icon: LucideIcons.calendar,
      label: 'Club Calendar',
      destination: SidebarDestination.clubCalendar,
      section: 'Club Management',
      coachOrAdmin: true,
    ),
    const NavItem(
      icon: LucideIcons.users,
      label: 'Members',
      destination: SidebarDestination.members,
      section: 'Club Management',
      coachOrAdmin: true,
    ),
    const NavItem(
      icon: LucideIcons.mapPin,
      label: 'Venues',
      destination: SidebarDestination.venues,
      section: 'Club Management',
      coachOrAdmin: true,
    ),
    const NavItem(
      icon: LucideIcons.usersRound,
      label: 'Groups',
      destination: SidebarDestination.groups,
      section: 'Club Management',
      coachOrAdmin: true,
    ),
    if (eventTypes.contains(EventType.programme))
      const NavItem(
        icon: LucideIcons.trophy,
        label: 'Programmes',
        destination: SidebarDestination.programmes,
        section: 'Club Management',
        coachOrAdmin: true,
      ),
    if (eventTypes.contains(EventType.camp))
      const NavItem(
        icon: LucideIcons.tent,
        label: 'Camps',
        destination: SidebarDestination.camps,
        section: 'Club Management',
        coachOrAdmin: true,
      ),
    if (eventTypes.contains(EventType.oneOff))
      const NavItem(
        icon: LucideIcons.calendarCheck,
        label: 'One-off Events',
        destination: SidebarDestination.oneOff,
        section: 'Club Management',
        coachOrAdmin: true,
      ),
    if (evaluations)
      const NavItem(
        icon: LucideIcons.clipboardPen,
        label: 'Reviews',
        destination: SidebarDestination.reviews,
        section: 'Club Management',
        coachOrAdmin: true,
      ),
    NavItem(
      icon: LucideIcons.inbox,
      label: 'Inquiries',
      destination: SidebarDestination.inquiries,
      section: 'Admin',
      adminOnly: true,
      badgeCount: unhandledInquiries,
    ),
    const NavItem(
      icon: LucideIcons.image,
      label: 'Website media',
      destination: SidebarDestination.siteMedia,
      section: 'Admin',
      superAdminOnly: true,
    ),
    const NavItem(
      icon: LucideIcons.building,
      label: 'Club details',
      destination: SidebarDestination.clubDetails,
      section: 'Admin',
      superAdminOnly: true,
    ),
    const NavItem(
      icon: LucideIcons.user,
      label: 'Profile',
      destination: SidebarDestination.profile,
      section: 'Account',
    ),
    const NavItem(
      icon: LucideIcons.messageCircle,
      label: 'Contact us',
      destination: SidebarDestination.contact,
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

    String routeOf(NavItem item) =>
        routeFor(item.destination, currentUser.username);
    final allPaths = visibleItems.map(routeOf).toList();

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

      final effectivePath = routeOf(item);

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
          highlightBackground: item.destination != SidebarDestination.dashboard,
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
