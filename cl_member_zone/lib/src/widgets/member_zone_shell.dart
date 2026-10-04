import 'package:cl_club_branding/cl_club_branding.dart' show AppFooter;
import 'package:cl_member_auth/cl_member_auth.dart'
    show SessionCountdown, authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        bumpManualRefresh,
        clUnhandledInquiryCountProvider,
        clubEventTypesProvider,
        currentUserProvider,
        evaluationsProvider,
        unreadNotificationCountProvider;
import 'package:cl_server_config/cl_server_config.dart'
    show NetworkStatusWrapper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'profile_menu_button.dart';
import 'sidebar/app_sidebar.dart';
import 'splash_view.dart';

/// Shell scaffold for the authenticated member zone (`/memberzone/*`).
///
/// Provides a responsive sidebar using [AppSidebar], a top bar with
/// sign-out, and wraps content with [NetworkStatusWrapper].
///
/// Navigation and theme-toggle are wired by the host (see
/// `app/lib/router.dart`); the shell itself holds no hardcoded routes.
class MemberZoneShell extends ConsumerStatefulWidget {
  const MemberZoneShell({
    required this.child,
    required this.isDark,
    required this.onToggleTheme,
    required this.onLogoTap,
    required this.onProfile,
    required this.onNotifications,
    required this.onAfterSignOut,
    required this.onNavigate,
    super.key,
  });

  final Widget child;

  /// Whether the current effective theme is dark — used to render the
  /// sun/moon icon in the top bar.
  final bool isDark;

  /// Called when the user taps the theme toggle icon.
  final VoidCallback onToggleTheme;

  /// Called when the user taps the sidebar brand header.
  final VoidCallback onLogoTap;

  /// Called when the user taps "Profile" in the avatar popover.
  final VoidCallback onProfile;

  /// Called when the user taps the bell icon.
  final VoidCallback onNotifications;

  /// Called after the user signs out, so the host can redirect.
  final VoidCallback onAfterSignOut;

  /// Navigates to a sidebar destination path. The host owns navigation.
  final ValueChanged<String> onNavigate;

  @override
  ConsumerState<MemberZoneShell> createState() => MemberZoneShellState();
}

class MemberZoneShellState extends ConsumerState<MemberZoneShell> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> signOut() async {
    await ref.read(authStateProvider.notifier).logout();
    if (mounted) widget.onAfterSignOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SplashView();

    final theme = ShadTheme.of(context);
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final hasUnread = unreadCount > 0;
    // Admin only: the inbox master never loads for anyone else.
    final unhandledInquiries = user.isAdmin
        ? ref.watch(clUnhandledInquiryCountProvider)
        : 0;
    final isDark = widget.isDark;
    final evaluations = ref.watch(evaluationsProvider) ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet =
            constraints.maxWidth >= 768 && constraints.maxWidth < 1200;
        final isMobile = constraints.maxWidth < 768;

        final topBar = Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.card,
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.border),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    if (isMobile)
                      IconButton(
                        icon: const Icon(LucideIcons.menu, size: 20),
                        onPressed: () => scaffoldKey.currentState?.openDrawer(),
                      ),
                    const Spacer(),
                    const SessionCountdown(),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(LucideIcons.refreshCw, size: 18),
                      tooltip: 'Refresh',
                      onPressed: () => bumpManualRefresh(ref),
                    ),
                    IconButton(
                      icon: Icon(
                        isDark ? LucideIcons.sun : LucideIcons.moon,
                        size: 18,
                      ),
                      tooltip: isDark
                          ? 'Switch to light theme'
                          : 'Switch to dark theme',
                      onPressed: widget.onToggleTheme,
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.bell, size: 18),
                          tooltip: hasUnread
                              ? '$unreadCount unread '
                                    'notification${unreadCount == 1 ? '' : 's'}'
                              : 'Notifications',
                          onPressed: widget.onNotifications,
                        ),
                        if (hasUnread)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.card,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    ProfileMenuButton(
                      username: user.username,
                      displayName: user.displayName,
                      onProfile: widget.onProfile,
                      onSignOut: signOut,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        if (isMobile) {
          return Scaffold(
            key: scaffoldKey,
            drawer: SizedBox(
              width: 240,
              child: AppSidebar(
                currentUser: user,
                pathPrefix: '/memberzone',
                eventTypes: ref.watch(clubEventTypesProvider),
                evaluations: evaluations,
                unhandledInquiries: unhandledInquiries,
                onLogoTap: widget.onLogoTap,
                onNavigate: widget.onNavigate,
              ),
            ),
            body: Column(
              children: [
                topBar,
                Expanded(
                  child: NetworkStatusWrapper(child: widget.child),
                ),
                const AppFooter(),
              ],
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              AppSidebar(
                currentUser: user,
                pathPrefix: '/memberzone',
                eventTypes: ref.watch(clubEventTypesProvider),
                evaluations: evaluations,
                unhandledInquiries: unhandledInquiries,
                isCollapsed: isTablet,
                onLogoTap: widget.onLogoTap,
                onNavigate: widget.onNavigate,
              ),
              Expanded(
                child: Column(
                  children: [
                    topBar,
                    Expanded(
                      child: NetworkStatusWrapper(child: widget.child),
                    ),
                    const AppFooter(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
