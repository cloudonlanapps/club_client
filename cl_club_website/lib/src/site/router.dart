import 'package:cl_club_website/cl_club_website.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'layouts/public_shell_scaffold.dart';

// =============================================================================
// PAGE TRANSITIONS
// =============================================================================

/// Available transition types - change [_activeTransitionIndex] to switch
enum PageTransitionType {
  none, // 0: No animation (instant)
  fade, // 1: Simple fade in/out
  slideRight, // 2: Slide from right (push) / to right (pop)
  slideUp, // 3: Slide from bottom (push) / to bottom (pop)
  slideAndFade, // 4: Slide + fade combined
  scale, // 5: Scale up (push) / scale down (pop)
  scaleAndFade, // 6: Scale + fade combined
  cupertino, // 7: iOS-style slide with parallax
}

/// Change this index to switch transition type globally
/// 0=none, 1=fade, 2=slideRight, 3=slideUp, 4=slideAndFade, 5=scale,
/// 6=scaleAndFade, 7=cupertino
const int _activeTransitionIndex = 4;

/// Creates a CustomTransitionPage with the selected transition type, over
/// CustomTransitionPage's default 300 ms.
CustomTransitionPage<T> buildTransitionPage<T>({
  required Widget child,
  LocalKey? key,
}) {
  final type = PageTransitionType.values[_activeTransitionIndex];

  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return _buildTransition(type, animation, secondaryAnimation, child);
    },
  );
}

Widget _buildTransition(
  PageTransitionType type,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  switch (type) {
    case PageTransitionType.none:
      return child;

    case PageTransitionType.fade:
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      );

    case PageTransitionType.slideRight:
      // Push: slide in from right, Pop: slide out to right
      final slideIn = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      final slideOut =
          Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.3, 0),
          ).animate(
            CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeInOut,
            ),
          );

      return SlideTransition(
        position: slideOut,
        child: SlideTransition(position: slideIn, child: child),
      );

    case PageTransitionType.slideUp:
      final slideIn = Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      return SlideTransition(position: slideIn, child: child);

    case PageTransitionType.slideAndFade:
      final slideIn = Tween<Offset>(
        begin: const Offset(0.05, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      final fadeIn = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      );

      final slideOut =
          Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.05, 0),
          ).animate(
            CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeInOut,
            ),
          );

      final fadeOut = Tween<double>(begin: 1, end: 0.9).animate(
        CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInOut),
      );

      return SlideTransition(
        position: slideOut,
        child: FadeTransition(
          opacity: fadeOut,
          child: SlideTransition(
            position: slideIn,
            child: FadeTransition(opacity: fadeIn, child: child),
          ),
        ),
      );

    case PageTransitionType.scale:
      final scaleIn = Tween<double>(
        begin: 0.9,
        end: 1,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      final scaleOut = Tween<double>(begin: 1, end: 1.1).animate(
        CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInOut),
      );

      return ScaleTransition(
        scale: scaleOut,
        child: ScaleTransition(scale: scaleIn, child: child),
      );

    case PageTransitionType.scaleAndFade:
      final scaleIn = Tween<double>(
        begin: 0.95,
        end: 1,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      final fadeIn = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      );

      final scaleOut = Tween<double>(begin: 1, end: 0.95).animate(
        CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInOut),
      );
      final fadeOut = Tween<double>(begin: 1, end: 0.5).animate(
        CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInOut),
      );

      return ScaleTransition(
        scale: scaleOut,
        child: FadeTransition(
          opacity: fadeOut,
          child: ScaleTransition(
            scale: scaleIn,
            child: FadeTransition(opacity: fadeIn, child: child),
          ),
        ),
      );

    case PageTransitionType.cupertino:
      // iOS-style: incoming page slides from right, outgoing slides left with
      // parallax
      final slideIn = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      final slideOut =
          Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-0.33, 0),
          ).animate(
            CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.linearToEaseOut,
            ),
          );

      // Add shadow to incoming page
      return SlideTransition(
        position: slideOut,
        child: SlideTransition(
          position: slideIn,
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15 * animation.value),
                  blurRadius: 20,
                  offset: const Offset(-5, 0),
                ),
              ],
            ),
            child: child,
          ),
        ),
      );
  }
}

// =============================================================================
// ROUTER CONFIGURATION
// =============================================================================

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      // Public section - ShellRoute with static navbar
      ShellRoute(
        builder: (context, state, child) => PublicShellScaffold(child: child),
        routes: [
          // Root route - uses key from extra to force rebuild when navigating
          // to home
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => buildTransitionPage(
              key: ValueKey(state.extra ?? 'home'),
              child: const LandingPage(),
            ),
          ),
          GoRoute(
            path: '/public/about-us',
            pageBuilder: (context, state) => buildTransitionPage(
              key: state.pageKey,
              child: const TheClubPage(),
            ),
          ),
          GoRoute(
            path: '/public/programs',
            pageBuilder: (context, state) => buildTransitionPage(
              key: state.pageKey,
              child: const TrainingSessionsPage(),
            ),
          ),
          GoRoute(
            path: '/public/events',
            pageBuilder: (context, state) => buildTransitionPage(
              key: state.pageKey,
              child: const LearningCampsPage(),
            ),
          ),
          GoRoute(
            path: '/public/events/:publicId',
            pageBuilder: (context, state) => buildTransitionPage(
              key: state.pageKey,
              child: EventDetailPage(
                publicId: state.pathParameters['publicId']!,
                notFoundKey: 'event',
              ),
            ),
          ),
          GoRoute(
            path: '/public/one-off',
            pageBuilder: (context, state) => buildTransitionPage(
              key: state.pageKey,
              child: const ClubEventsPage(),
            ),
          ),
          GoRoute(
            path: '/public/coaches',
            pageBuilder: (context, state) => buildTransitionPage(
              key: state.pageKey,
              child: const IceMastersPage(),
            ),
          ),
          GoRoute(
            path: '/public/rinks',
            pageBuilder: (context, state) => buildTransitionPage(
              key: state.pageKey,
              child: const TheRinksPage(),
            ),
          ),
          GoRoute(
            path: '/public/contact-us',
            pageBuilder: (context, state) => buildTransitionPage(
              key: state.pageKey,
              child: const ContactUsPage(),
            ),
          ),
          GoRoute(
            path: '/public/rink/:publicId',
            pageBuilder: (context, state) => buildTransitionPage(
              key: state.pageKey,
              child: VenuePage(publicId: state.pathParameters['publicId']!),
            ),
          ),
          // The "Coming Soon" page, and where the event-card CTAs
          // ("Register Now" / "Join Now") land. site#7 turns it into the
          // interest form.
          GoRoute(
            path: '/auth/signup',
            pageBuilder: (context, state) => buildTransitionPage(
              key: state.pageKey,
              child: const SignupPage(),
            ),
          ),
        ],
      ),
    ],
  );
});
