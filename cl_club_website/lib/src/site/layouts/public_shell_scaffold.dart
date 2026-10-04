import 'package:cl_club_branding/cl_club_branding.dart' show ContactFab;
import 'package:cl_club_website/cl_club_website.dart'
    show contactFabVisibilityProvider, navbarVisibilityProvider;
import 'package:cl_server_config/cl_server_config.dart'
    show NetworkStatusWrapper;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/mobile_menu_drawer.dart';
import '../widgets/public_navbar.dart';

const double _navbarHeight = 64;

/// Routes that render entirely from bundled assets and must not be
/// replaced by the network failure screen when the server is down.
const _offlineRoutes = {'/public/contact-us'};

/// Shell scaffold for public pages that provides a static navbar and FAB.
///
/// The navbar stays fixed during page transitions while only the
/// child content animates. Navbar visibility is controlled by
/// [navbarVisibilityProvider] with a fade transition.
///
/// The contact FAB visibility is controlled by [contactFabVisibilityProvider].
/// Landing page sets it to false (has its own animated FAB).
///
/// NOTE: A mobile-only "hide navbar on scroll down" behavior previously
/// combined [navbarVisibilityProvider] with `scrollDirectionProvider`. That
/// wiring has been removed; see lib/src/providers/scroll_direction.dart in
/// the club_website package for the retained infrastructure and rationale.
class PublicShellScaffold extends ConsumerWidget {
  const PublicShellScaffold({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseVisible = ref.watch(navbarVisibilityProvider);
    final showFab = ref.watch(contactFabVisibilityProvider);
    final showNavbar = baseVisible;

    // Offline-capable routes (e.g. Contact Us) must render even when the
    // server is unreachable, so we skip the network failure overlay there.
    final location = GoRouterState.of(context).uri.path;
    final skipNetworkCheck = _offlineRoutes.contains(location);

    return Scaffold(
      // Every width: the navbar's menu button shows below 1000px and the
      // landing hero's on every width (club_core#180).
      endDrawer: const MobileMenuDrawer(),
      body: Stack(
        children: [
          // Main content - takes full space, wrapped with network status check
          Positioned.fill(
            child: skipNetworkCheck
                ? child
                : NetworkStatusWrapper(child: child),
          ),
          // Navbar with slide + fade transition
          AnimatedPositioned(
            top: showNavbar ? 0 : -_navbarHeight,
            left: 0,
            right: 0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              opacity: showNavbar ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !showNavbar,
                child: const PublicNavbar(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: showFab ? const ContactFab() : null,
    );
  }
}
