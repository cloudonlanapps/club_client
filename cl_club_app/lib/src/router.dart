import 'dart:async';

import 'package:cl_club_branding/cl_club_branding.dart' show ThemeModeWidgetRef;
import 'package:cl_club_communication/cl_club_communication.dart'
    show
        NotifAdminUserLink,
        NotifAdminUserReviewLink,
        NotifCreditLink,
        NotifEvaluationLink,
        NotifEventLink,
        NotifGroupLink,
        NotifInquiriesLink,
        NotifMyEventLink,
        NotifMyEventsHomeLink,
        NotifMyGroupsLink,
        NotifMyReviewLink,
        NotifMyReviewsLink,
        NotifOccurrenceLink,
        NotifSelfProfileLink,
        NotifVenueLink,
        NotificationDeepLink;
import 'package:cl_club_events/cl_club_events.dart' show MyEventsSection;
import 'package:cl_member_auth/cl_member_auth.dart'
    show
        AuthShell,
        ForgotPasswordScreen,
        LoginScreen,
        SignupScreen,
        SignupSuccessScreen,
        authStateProvider;
import 'package:cl_member_onboarding/cl_member_onboarding.dart'
    show
        OnboardingShell,
        OnboardingSubmitDocumentsScreen,
        OnboardingWelcomeScreen,
        allowedOnboardingPaths,
        onboardingWelcomePath;
import 'package:cl_member_zone/cl_member_zone.dart'
    show
        AdminGroupProfileScreen,
        AdminUserProfileScreen,
        AdminUserReviewScreen,
        AuditLogScreen,
        BroadcastScreen,
        ClubIdentityScreen,
        CreditScreen,
        DashboardScreen,
        EventDetailsScreen,
        EventEnrolmentsScreen,
        EventOccurencesAttendanceScreen,
        EventsCalendarScreen,
        EventsCampsNewScreen,
        EventsCampsScreen,
        EventsOneOffNewScreen,
        EventsOneOffScreen,
        EventsProgrammesNewScreen,
        EventsProgrammesScreen,
        GroupCreateScreen,
        GroupJoinRequestsScreen,
        GroupMembersScreen,
        GroupsScreen,
        InquiriesScreen,
        MemberZoneShell,
        MyEventDetailsScreen,
        MyEventsAllScreen,
        MyEventsAttendanceScreen,
        MyEventsCalendarScreen,
        MyGroupDetailsScreen,
        MyGroupsScreen,
        MyVenueDetailScreen,
        NotificationsListScreen,
        PendingActionsListScreen,
        ProfileScreen,
        PublicProfileScreen,
        SiteMediaScreen,
        UserCreateScreen,
        UsersScreen,
        VenueCreateScreen,
        VenueProfileScreen,
        VenuesScreen;
import 'package:cl_remote_store/cl_remote_store.dart'
    show AuditLogScope, identityVerificationProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_lib/ui_lib.dart' show StringExtensions;

import 'providers/public_site_uri.dart';
import 'review_routes.dart';
import 'screens/contact_screen.dart';
import 'utils/after_sign_out.dart';
import 'utils/router_helpers.dart';

// =============================================================================
// PAGE TRANSITIONS
// =============================================================================

enum PageTransitionType {
  none,
  fade,
  slideRight,
  slideUp,
  slideAndFade,
  scale,
  scaleAndFade,
  cupertino,
}

const int activeTransitionIndex = 4;

CustomTransitionPage<T> buildTransitionPage<T>({
  required Widget child,
  LocalKey? key,
}) {
  final type = PageTransitionType.values[activeTransitionIndex];

  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return buildTransition(type, animation, secondaryAnimation, child);
    },
  );
}

Widget buildTransition(
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

final rootNavigatorKey = GlobalKey<NavigatorState>();

void routeNotificationLink(BuildContext context, NotificationDeepLink link) {
  final router = GoRouter.of(context);
  // `?notif=N` carries the originating notification id so the destination
  // screen can offer a "Delete notification" action when its target row
  // no longer exists. Consumed by EventDetailsScreen, MyEventDetailsScreen,
  // EventOccurencesAttendanceScreen, and GroupProfileView.
  final q = link.sourceNotificationId != null
      ? '?notif=${link.sourceNotificationId}'
      : '';
  switch (link) {
    case NotifEventLink(:final eventId):
      unawaited(router.push('/memberzone/events/$eventId$q'));
    case NotifMyEventLink(:final username, :final eventId):
      unawaited(router.push('/memberzone/my-events/$username/$eventId$q'));
    case NotifGroupLink(:final groupId):
      unawaited(router.push('/memberzone/groups/$groupId$q'));
    case NotifMyGroupsLink(:final username):
      unawaited(router.push('/memberzone/my-groups/$username$q'));
    case NotifOccurrenceLink(:final eventId, :final occurrenceTimeUtc):
      final iso = occurrenceTimeUtc.toIso8601String();
      unawaited(router.push('/memberzone/events/$eventId/$iso/attendance$q'));
    case NotifVenueLink(:final venueId):
      unawaited(router.push('/memberzone/venues/$venueId$q'));
    case NotifSelfProfileLink():
      unawaited(router.push('/memberzone/profile$q'));
    case NotifMyEventsHomeLink(:final username):
      unawaited(router.push('/memberzone/my-events/$username$q'));
    case NotifAdminUserLink(:final username):
      unawaited(router.push('/memberzone/users/$username$q'));
    case NotifCreditLink(:final username):
      unawaited(router.push('/memberzone/credit/$username'));
    case NotifInquiriesLink():
      unawaited(router.push('/memberzone/inquiries'));
    case NotifMyReviewLink(:final evaluationId):
      unawaited(router.push(myReviewPath(evaluationId)));
    case NotifMyReviewsLink():
      unawaited(router.push(myReviewsPath));
    case NotifEvaluationLink(:final evaluationId):
      unawaited(router.push(reviewEditPath(evaluationId)));
    case NotifAdminUserReviewLink(:final username):
      // Review route already takes `?username=…`, so append `&notif=…`
      // (not `?notif=…`) when carrying the source notification id.
      final notif = link.sourceNotificationId != null
          ? '&notif=${link.sourceNotificationId}'
          : '';
      unawaited(
        router.push('/memberzone/users/review?username=$username$notif'),
      );
  }
}

class RouterRefreshListenable extends ChangeNotifier {
  RouterRefreshListenable(Ref ref) {
    _sub = ref.listen(
      authStateProvider,
      (_, _) => notifyListeners(),
      fireImmediately: false,
    );
    // The onboarding routes depend on identity verification (#84), which
    // arrives after the first redirect.
    _capsSub = ref.listen(
      identityVerificationProvider,
      (_, _) => notifyListeners(),
      fireImmediately: false,
    );
  }
  late final ProviderSubscription<dynamic> _sub;
  late final ProviderSubscription<dynamic> _capsSub;

  @override
  void dispose() {
    _sub.close();
    _capsSub.close();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = RouterRefreshListenable(ref);
  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      // Don't redirect while restoring the session — let the destination
      // render its own loader.
      if (auth.isLoading) return null;
      final user = auth.valueOrNull;
      final loggedIn = user != null;
      final path = state.matchedLocation;
      final goingPrivate = path.startsWith('/memberzone');
      final goingAuth = path.startsWith('/auth/');
      final goingOnboarding = path.startsWith('/onboarding/');
      final isRoot = path == '/';

      // Logged out: send dashboard/onboarding traffic to login.
      if (!loggedIn) {
        if (goingPrivate || goingOnboarding || isRoot) return '/auth/login';
        return null;
      }

      // Logged in: status-gated routing (see allowedOnboardingPaths). The
      // welcome page is always legal for `registered` and `pending` users;
      // the document step only without an admin review note, and never on
      // a server that does not verify identity (#84).
      final onboarding = allowedOnboardingPaths(
        user,
        identityVerification: ref.read(identityVerificationProvider),
      );
      if (onboarding != null) {
        if (onboarding.contains(path)) return null;
        return onboardingWelcomePath;
      }

      // Active (or other non-blocking statuses).
      if (goingAuth || goingOnboarding) return '/';
      if (path == '/memberzone') return '/';
      return null;
    },
    routes: [
      // `/auth/**` — shared AuthShell stays mounted across navigations;
      // only the inner view swaps.
      ShellRoute(
        builder: (context, state, child) => AuthShell(child: child),
        routes: [
          GoRoute(
            path: '/auth/login',
            pageBuilder: (context, state) => buildTransitionPage(
              key: state.pageKey,
              child: LoginScreen(
                onLoginSuccess: () => context.go('/'),
                onNavigateToForgotPassword: () =>
                    context.go('/auth/forgot-password'),
                onNavigateToSignup: () => context.go('/auth/signup'),
              ),
            ),
          ),
          GoRoute(
            path: '/auth/signup',
            pageBuilder: (context, state) => buildTransitionPage(
              key: state.pageKey,
              child: SignupScreen(
                onSignupSuccess: () => context.go('/auth/signup-success'),
                onNavigateToLogin: () => context.go('/auth/login'),
              ),
            ),
          ),
          GoRoute(
            path: '/auth/signup-success',
            pageBuilder: (context, state) => buildTransitionPage(
              key: state.pageKey,
              child: SignupSuccessScreen(
                onHome: () => context.go('/auth/login'),
              ),
            ),
          ),
          GoRoute(
            path: '/auth/forgot-password',
            pageBuilder: (context, state) => buildTransitionPage(
              key: state.pageKey,
              child: ForgotPasswordScreen(
                onNavigateToLogin: () => context.go('/auth/login'),
              ),
            ),
          ),
        ],
      ),

      // `/onboarding/**` — shared OnboardingShell stays mounted across
      // navigations. Title + gate are derived from the active sub-route.
      ShellRoute(
        builder: (context, state, child) => Consumer(
          builder: (context, ref, _) {
            final isSubmitDocs =
                state.matchedLocation == '/onboarding/submit-documents';
            final isDark = ref.watchIsDark(context);
            return OnboardingShell(
              title: isSubmitDocs
                  ? (_) => 'Upload identity document'
                  : (u) => 'Welcome ${u.displayName.toTitleCase()}',
              onBack: isSubmitDocs
                  ? () => context.go('/onboarding/welcome')
                  : null,
              onRefresh: () => ref.invalidate(authStateProvider),
              onToggleTheme: () => ref.toggleThemeMode(isDark: isDark),
              isDark: isDark,
              child: child,
            );
          },
        ),
        routes: [
          GoRoute(
            path: '/onboarding/welcome',
            pageBuilder: (context, state) => buildTransitionPage(
              key: state.pageKey,
              child: OnboardingWelcomeScreen(
                onContinue: () => context.go('/onboarding/submit-documents'),
                onHome: () => context.go('/'),
              ),
            ),
          ),
          GoRoute(
            path: '/onboarding/submit-documents',
            pageBuilder: (context, state) => buildTransitionPage(
              key: state.pageKey,
              child: OnboardingSubmitDocumentsScreen(
                onHome: () => context.go('/'),
              ),
            ),
          ),
        ],
      ),

      // Authenticated member zone — sidebar shell.
      ShellRoute(
        builder: (context, state, child) => Consumer(
          builder: (context, ref, _) {
            final isDark = ref.watchIsDark(context);
            return MemberZoneShell(
              isDark: isDark,
              onToggleTheme: () => ref.toggleThemeMode(isDark: isDark),
              onLogoTap: () => context.go('/memberzone/contact'),
              onProfile: () => context.go('/memberzone/profile'),
              onNotifications: () => context.go('/memberzone/notifications'),
              onAfterSignOut: () =>
                  afterSignOut(context, ref.read(publicSiteUriProvider)),
              onNavigate: (path) => context.go(path),
              child: child,
            );
          },
        ),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => NoTransitionPage(
              child: DashboardScreen(
                onAdminEventTap: (eventId) =>
                    context.push('/memberzone/events/$eventId'),
                onMyEventTap: (username, eventId) => GoRouter.of(
                  context,
                ).push('/memberzone/my-events/$username/$eventId'),
                onSeeMoreNotifications: () =>
                    context.push('/memberzone/notifications'),
                onSeeMorePendingActions: () =>
                    GoRouter.of(context).push('/memberzone/pending-actions'),
                onNotificationDeepLink: (link) =>
                    routeNotificationLink(context, link),
                onCreateUser: () => context.push('/memberzone/users/new'),
                onCreateGroup: () => context.push('/memberzone/groups/new'),
                onCreateEvent: (type) =>
                    context.push('${eventsListPath(type)}/new'),
                onAnnouncement: () => context.push('/memberzone/broadcast'),
                onAuditLog: () => context.push('/memberzone/audit-log'),
                onHome: () => context.go('/'),
              ),
            ),
          ),
          GoRoute(
            path: '/memberzone/notifications',
            pageBuilder: (context, state) => NoTransitionPage(
              child: NotificationsListScreen(
                onDeepLink: (link) => routeNotificationLink(context, link),
                onHome: () => context.go('/'),
                onBack: context.canPop() ? () => context.pop() : null,
              ),
            ),
          ),
          GoRoute(
            path: '/memberzone/broadcast',
            pageBuilder: (context, state) => NoTransitionPage(
              child: BroadcastScreen(
                onClose: () => popOrGo(context, '/'),
                onHome: () => context.go('/'),
              ),
            ),
          ),
          GoRoute(
            path: '/memberzone/pending-actions',
            pageBuilder: (context, state) => NoTransitionPage(
              child: PendingActionsListScreen(
                onDeepLink: (link) => routeNotificationLink(context, link),
                onHome: () => context.go('/'),
                // Always show a back button (canPop() reads false inside the
                // shell pageBuilder even for pushed routes); pop when
                // poppable, else fall back to the dashboard.
                onBack: () => popOrGo(context, '/'),
              ),
            ),
          ),
          GoRoute(
            path: '/memberzone/my-events/:targetUsername',
            pageBuilder: (context, state) {
              final targetUsername = state.pathParameters['targetUsername']!;
              return NoTransitionPage(
                child: MyEventsAllScreen(
                  targetUsername: targetUsername,
                  onEventTap: (eventId) => context.push(
                    '/memberzone/my-events/$targetUsername/$eventId',
                  ),
                  onHome: () => context.go('/'),
                  onBack: context.canPop() ? () => context.pop() : null,
                ),
              );
            },
          ),
          GoRoute(
            path: '/memberzone/my-groups/:targetUsername',
            pageBuilder: (context, state) {
              final targetUsername = state.pathParameters['targetUsername']!;
              return NoTransitionPage(
                child: MyGroupsScreen(
                  targetUsername: targetUsername,
                  onGroupTap: (groupId) => context.push(
                    '/memberzone/my-groups/$targetUsername/$groupId',
                  ),
                  onHome: () => context.go('/'),
                  onBack: context.canPop() ? () => context.pop() : null,
                ),
              );
            },
          ),
          GoRoute(
            path: '/memberzone/my-groups/:targetUsername/:groupId',
            pageBuilder: (context, state) {
              final targetUsername = state.pathParameters['targetUsername']!;
              final groupId = int.parse(state.pathParameters['groupId']!);
              return NoTransitionPage(
                child: MyGroupDetailsScreen(
                  targetUsername: targetUsername,
                  groupId: groupId,
                  onHome: () => context.go('/'),
                  // Always show a back button (canPop() reads false inside the
                  // shell pageBuilder even for pushed routes); pop when
                  // poppable, else fall back to the user's groups list.
                  onBack: () =>
                      popOrGo(context, '/memberzone/my-groups/$targetUsername'),
                ),
              );
            },
          ),
          GoRoute(
            path: '/memberzone/my-events/:targetUsername/calendar',
            pageBuilder: (context, state) {
              final targetUsername = state.pathParameters['targetUsername']!;
              return NoTransitionPage(
                child: MyEventsCalendarScreen(
                  targetUsername: targetUsername,
                  onEventTap: (eventId) => context.push(
                    '/memberzone/my-events/$targetUsername/$eventId',
                  ),
                  onHome: () => context.go('/'),
                  onBack: context.canPop() ? () => context.pop() : null,
                ),
              );
            },
          ),
          GoRoute(
            path: '/memberzone/my-events/:targetUsername/attendance',
            pageBuilder: (context, state) {
              final targetUsername = state.pathParameters['targetUsername']!;
              return NoTransitionPage(
                child: MyEventsAttendanceScreen(
                  targetUsername: targetUsername,
                  onHome: () => context.go('/'),
                  onBack: context.canPop() ? () => context.pop() : null,
                ),
              );
            },
          ),
          GoRoute(
            path: '/memberzone/my-events/:targetUsername/:eventId',
            pageBuilder: (context, state) {
              final targetUsername = state.pathParameters['targetUsername']!;
              final eventId = int.parse(state.pathParameters['eventId']!);
              final notifParam = state.uri.queryParameters['notif'];
              final sourceNotificationId = notifParam == null
                  ? null
                  : int.tryParse(notifParam);
              return NoTransitionPage(
                child: MyEventDetailsScreen(
                  targetUsername: targetUsername,
                  eventId: eventId,
                  sourceNotificationId: sourceNotificationId,
                  onVenueTap: (venueId) => GoRouter.of(
                    context,
                  ).push('/memberzone/my-venues/$venueId'),
                  onPublicProfileTap: (publicId) => GoRouter.of(
                    context,
                  ).push('/memberzone/profile/$publicId'),
                  onHome: () => context.go('/'),
                  onDismissed: () => popOrGo(context, '/'),
                  // Always show a back button (canPop() reads false inside the
                  // shell pageBuilder even for pushed routes); pop when
                  // poppable, else fall back to the dashboard.
                  onBack: () => popOrGo(context, '/'),
                ),
              );
            },
          ),
          GoRoute(
            path: '/memberzone/my-venues/:id',
            pageBuilder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return NoTransitionPage(
                child: MyVenueDetailScreen(
                  venueId: id,
                ),
              );
            },
          ),
          GoRoute(
            path: '/memberzone/users',
            pageBuilder: (context, state) => NoTransitionPage(
              child: UsersScreen(
                onUserTap: (username) =>
                    context.push('/memberzone/users/$username'),
                onReviewUser: (username) =>
                    context.push('/memberzone/users/review?username=$username'),
                onCreateUser: () => context.push('/memberzone/users/new'),
                onHome: () => context.go('/'),
                onBack: context.canPop() ? () => context.pop() : null,
              ),
            ),
          ),
          GoRoute(
            path: '/memberzone/users/review',
            pageBuilder: (context, state) {
              final username = state.uri.queryParameters['username'] ?? '';
              return NoTransitionPage(
                child: AdminUserReviewScreen(
                  username: username,
                  onBack: () => popOrGo(context, '/memberzone/users'),
                ),
              );
            },
          ),
          GoRoute(
            path: '/memberzone/users/new',
            pageBuilder: (context, state) => NoTransitionPage(
              child: UserCreateScreen(
                onCreated: () => popOrGo(context, '/memberzone/users'),
                onCancel: () => popOrGo(context, '/memberzone/users'),
              ),
            ),
          ),
          GoRoute(
            path: '/memberzone/users/:targetUsername',
            pageBuilder: (context, state) {
              final targetUsername = state.pathParameters['targetUsername']!;
              return NoTransitionPage(
                child: AdminUserProfileScreen(
                  targetUsername: targetUsername,
                  onReview: () => GoRouter.of(
                    context,
                  ).push('/memberzone/users/review?username=$targetUsername'),
                  eventsSection: (u) => MyEventsSection(
                    username: u,
                    enrolledOnly: true,
                    onEventTap: (event) => GoRouter.of(
                      context,
                    ).push('/memberzone/my-events/$u/${event.id}'),
                  ),
                  // Always show a back button (canPop() reads false inside the
                  // shell pageBuilder even for pushed routes); pop when
                  // poppable, else fall back to the members list.
                  onBack: () => popOrGo(context, '/memberzone/users'),
                  onHistory: () => GoRouter.of(
                    context,
                  ).push('/memberzone/audit-log/user/$targetUsername'),
                  onOpenReview: (id) => context.push(reviewEditPath(id)),
                ),
              );
            },
          ),
          GoRoute(
            path: '/memberzone/profile/:publicId',
            pageBuilder: (context, state) {
              final publicId = state.pathParameters['publicId']!;
              return NoTransitionPage(
                child: PublicProfileScreen(
                  publicId: publicId,
                  onHome: () => context.go('/'),
                  onBack: () => popOrGo(context, '/'),
                ),
              );
            },
          ),
          GoRoute(
            path: '/memberzone/venues',
            pageBuilder: (context, state) => NoTransitionPage(
              child: VenuesScreen(
                onVenueTap: (venue) =>
                    GoRouter.of(context).push('/memberzone/venues/${venue.id}'),
                onCreateVenue: () => context.push('/memberzone/venues/new'),
                onBack: context.canPop() ? () => context.pop() : null,
              ),
            ),
          ),
          GoRoute(
            path: '/memberzone/venues/new',
            pageBuilder: (context, state) => NoTransitionPage(
              child: VenueCreateScreen(
                onCreated: () => context.pop(),
                onCancel: () => context.pop(),
              ),
            ),
          ),
          GoRoute(
            path: '/memberzone/venues/:id',
            pageBuilder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return NoTransitionPage(
                child: VenueProfileScreen(
                  venueId: id,
                  onDeleted: () => context.go('/memberzone/venues'),
                  // Always show a back button (canPop() reads false inside the
                  // shell pageBuilder even for pushed routes); pop when
                  // poppable, else fall back to the venues list.
                  onBack: () => popOrGo(context, '/memberzone/venues'),
                  onHistory: () => GoRouter.of(
                    context,
                  ).push('/memberzone/audit-log/venue/$id'),
                ),
              );
            },
          ),
          GoRoute(
            path: '/memberzone/groups',
            pageBuilder: (context, state) => NoTransitionPage(
              child: GroupsScreen(
                onGroupTap: (group) =>
                    GoRouter.of(context).push('/memberzone/groups/${group.id}'),
                onCreateGroup: () => context.push('/memberzone/groups/new'),
                onHome: () => context.go('/'),
                onBack: context.canPop() ? () => context.pop() : null,
              ),
            ),
          ),
          GoRoute(
            path: '/memberzone/groups/new',
            pageBuilder: (context, state) => NoTransitionPage(
              child: GroupCreateScreen(
                onCreated: () => context.pop(),
                onCancel: () => context.pop(),
              ),
            ),
          ),
          GoRoute(
            path: '/memberzone/groups/:id',
            pageBuilder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              final notifParam = state.uri.queryParameters['notif'];
              final sourceNotificationId = notifParam == null
                  ? null
                  : int.tryParse(notifParam);
              return NoTransitionPage(
                child: AdminGroupProfileScreen(
                  groupId: id,
                  sourceNotificationId: sourceNotificationId,
                  onOpenRequests: () => GoRouter.of(
                    context,
                  ).push('/memberzone/groups/$id/requests'),
                  onOpenAllMembers: () => GoRouter.of(
                    context,
                  ).push('/memberzone/groups/$id/members'),
                  onDeleted: () => popOrGo(context, '/memberzone/groups'),
                  // Always show a back button (canPop() reads false inside the
                  // shell pageBuilder even for pushed routes); pop when
                  // poppable, else fall back to the groups list.
                  onBack: () => popOrGo(context, '/memberzone/groups'),
                  onHistory: () => GoRouter.of(
                    context,
                  ).push('/memberzone/audit-log/group/$id'),
                ),
              );
            },
          ),
          GoRoute(
            path: '/memberzone/groups/:id/members',
            pageBuilder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return NoTransitionPage(
                child: GroupMembersScreen(
                  groupId: id,
                  onRemoved: () => popOrGo(context, '/memberzone/groups'),
                  // Always show a back button (canPop() reads false inside the
                  // shell pageBuilder even for pushed routes); pop when
                  // poppable, else fall back to the group detail.
                  onBack: () => popOrGo(context, '/memberzone/groups/$id'),
                ),
              );
            },
          ),
          GoRoute(
            path: '/memberzone/groups/:id/requests',
            pageBuilder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return NoTransitionPage(
                child: GroupJoinRequestsScreen(
                  groupId: id,
                  onHome: () => context.go('/'),
                  // Always show a back button (canPop() reads false inside the
                  // shell pageBuilder even for pushed routes); pop when
                  // poppable, else fall back to the group detail.
                  onBack: () => popOrGo(context, '/memberzone/groups/$id'),
                ),
              );
            },
          ),
          GoRoute(
            path: '/memberzone/events/calendar',
            pageBuilder: (context, state) => NoTransitionPage(
              child: EventsCalendarScreen(
                onMarkAttendance: (eventId, occurrenceTimeUtc) => context.push(
                  '/memberzone/events/$eventId/'
                  '${occurrenceTimeUtc.toIso8601String()}/attendance',
                ),
                onHome: () => context.go('/'),
                onBack: context.canPop() ? () => context.pop() : null,
              ),
            ),
          ),
          GoRoute(
            path: '/memberzone/events/camps',
            pageBuilder: (context, state) => NoTransitionPage(
              child: EventsCampsScreen(
                onEventTap: (event) =>
                    GoRouter.of(context).push('/memberzone/events/${event.id}'),
                onEnrollments: (event) => GoRouter.of(
                  context,
                ).push('/memberzone/events/${event.id}/enrollments'),
                onCreateNew: () => context.push('/memberzone/events/camps/new'),
                onHome: () => context.go('/'),
                onBack: context.canPop() ? () => context.pop() : null,
              ),
            ),
          ),
          GoRoute(
            path: '/memberzone/events/camps/new',
            pageBuilder: (context, state) => NoTransitionPage(
              child: EventsCampsNewScreen(
                onCreated: () => context.pop(),
                onCancel: () => context.pop(),
                onHome: () => context.go('/'),
              ),
            ),
          ),
          GoRoute(
            path: '/memberzone/events/one-off',
            pageBuilder: (context, state) => NoTransitionPage(
              child: EventsOneOffScreen(
                onEventTap: (event) =>
                    GoRouter.of(context).push('/memberzone/events/${event.id}'),
                onEnrollments: (event) => GoRouter.of(
                  context,
                ).push('/memberzone/events/${event.id}/enrollments'),
                onCreateNew: () =>
                    context.push('/memberzone/events/one-off/new'),
                onHome: () => context.go('/'),
                onBack: context.canPop() ? () => context.pop() : null,
              ),
            ),
          ),
          GoRoute(
            path: '/memberzone/events/one-off/new',
            pageBuilder: (context, state) => NoTransitionPage(
              child: EventsOneOffNewScreen(
                onCreated: () => context.pop(),
                onCancel: () => context.pop(),
                onHome: () => context.go('/'),
              ),
            ),
          ),
          GoRoute(
            path: '/memberzone/events/programmes',
            pageBuilder: (context, state) => NoTransitionPage(
              child: EventsProgrammesScreen(
                onEventTap: (event) =>
                    GoRouter.of(context).push('/memberzone/events/${event.id}'),
                onEnrollments: (event) => GoRouter.of(
                  context,
                ).push('/memberzone/events/${event.id}/enrollments'),
                onCreateNew: () =>
                    context.push('/memberzone/events/programmes/new'),
                onHome: () => context.go('/'),
                onBack: context.canPop() ? () => context.pop() : null,
              ),
            ),
          ),
          GoRoute(
            path: '/memberzone/events/programmes/new',
            pageBuilder: (context, state) => NoTransitionPage(
              child: EventsProgrammesNewScreen(
                onCreated: () => context.pop(),
                onCancel: () => context.pop(),
                onHome: () => context.go('/'),
              ),
            ),
          ),
          GoRoute(
            path: '/memberzone/events/:eventId',
            pageBuilder: (context, state) {
              final eventId = int.parse(state.pathParameters['eventId']!);
              final notifParam = state.uri.queryParameters['notif'];
              final sourceNotificationId = notifParam == null
                  ? null
                  : int.tryParse(notifParam);
              return NoTransitionPage(
                child: EventDetailsScreen(
                  eventId: eventId,
                  sourceNotificationId: sourceNotificationId,
                  onNavigateToEvent: (newId) => GoRouter.of(
                    context,
                  ).pushReplacement('/memberzone/events/$newId'),
                  onDeleted: () => popOrGo(context, '/'),
                  onManageEnrolments: (id) => GoRouter.of(
                    context,
                  ).push('/memberzone/events/$id/enrollments'),
                  onMemberTap: (username) =>
                      GoRouter.of(context).push('/memberzone/users/$username'),
                  onPublicProfileTap: (publicId) => GoRouter.of(
                    context,
                  ).push('/memberzone/profile/$publicId'),
                  onHome: () => context.go('/'),
                  onDismissed: () => popOrGo(context, '/'),
                  // Always show a back button (canPop() reads false inside the
                  // shell pageBuilder even for pushed routes); pop when
                  // poppable, else fall back to the camps list.
                  onBack: () => popOrGo(context, '/memberzone/events/camps'),
                  onHistory: () => GoRouter.of(
                    context,
                  ).push('/memberzone/audit-log/event/$eventId'),
                ),
              );
            },
          ),
          // The inbox of the public website's contact and interest forms
          // (club_core#21), admin only; reached from the sidebar's Admin
          // section.
          GoRoute(
            path: '/memberzone/inquiries',
            pageBuilder: (context, state) => NoTransitionPage(
              child: InquiriesScreen(
                onHome: () => context.go('/'),
                onBack: () => popOrGo(context, '/'),
              ),
            ),
          ),
          // The public website's media slots (club_core#19), super-admin
          // only; reached from the sidebar's Admin section.
          GoRoute(
            path: '/memberzone/site-media',
            pageBuilder: (context, state) => NoTransitionPage(
              child: SiteMediaScreen(
                onHome: () => context.go('/'),
                onBack: () => popOrGo(context, '/'),
              ),
            ),
          ),
          // The club's name, inquiry email and public contact block
          // (club_core#20), super-admin only; reached from the sidebar's
          // Admin section.
          GoRoute(
            path: '/memberzone/club-details',
            pageBuilder: (context, state) => NoTransitionPage(
              child: ClubIdentityScreen(
                onHome: () => context.go('/'),
                onBack: () => popOrGo(context, '/'),
              ),
            ),
          ),
          // Audit-log history. The global feed is super-admin-only; the
          // entity-scoped routes are reached from the history affordance in
          // each detail screen's title row (issue #207).
          GoRoute(
            path: '/memberzone/audit-log',
            pageBuilder: (context, state) => NoTransitionPage(
              child: AuditLogScreen(
                scope: const AuditLogScope.global(),
                title: 'Audit Log',
                onHome: () => context.go('/'),
                onBack: () => popOrGo(context, '/'),
              ),
            ),
          ),
          GoRoute(
            path: '/memberzone/audit-log/event/:eventId',
            pageBuilder: (context, state) {
              final eventId = int.parse(state.pathParameters['eventId']!);
              return NoTransitionPage(
                child: AuditLogScreen(
                  scope: AuditLogScope.event(eventId),
                  title: 'Event History',
                  onHome: () => context.go('/'),
                  onBack: () => popOrGo(context, '/memberzone/events/$eventId'),
                ),
              );
            },
          ),
          GoRoute(
            path: '/memberzone/audit-log/group/:groupId',
            pageBuilder: (context, state) {
              final groupId = int.parse(state.pathParameters['groupId']!);
              return NoTransitionPage(
                child: AuditLogScreen(
                  scope: AuditLogScope.group(groupId),
                  title: 'Group History',
                  onHome: () => context.go('/'),
                  onBack: () => popOrGo(context, '/memberzone/groups/$groupId'),
                ),
              );
            },
          ),
          GoRoute(
            path: '/memberzone/audit-log/venue/:venueId',
            pageBuilder: (context, state) {
              final venueId = int.parse(state.pathParameters['venueId']!);
              return NoTransitionPage(
                child: AuditLogScreen(
                  scope: AuditLogScope.venue(venueId),
                  title: 'Venue History',
                  onHome: () => context.go('/'),
                  onBack: () => popOrGo(context, '/memberzone/venues/$venueId'),
                ),
              );
            },
          ),
          GoRoute(
            path: '/memberzone/audit-log/user/:username',
            pageBuilder: (context, state) {
              final username = state.pathParameters['username']!;
              return NoTransitionPage(
                child: AuditLogScreen(
                  scope: AuditLogScope.user(username),
                  title: 'User History',
                  onHome: () => context.go('/'),
                  onBack: () => popOrGo(context, '/memberzone/users/$username'),
                ),
              );
            },
          ),
          GoRoute(
            path: '/memberzone/events/:eventId/enrollments',
            pageBuilder: (context, state) {
              final eventId = int.parse(state.pathParameters['eventId']!);
              return NoTransitionPage(
                child: EventEnrolmentsScreen(
                  eventId: eventId,
                  onHome: () => context.go('/'),
                  // Always show a back button (canPop() reads false inside the
                  // shell pageBuilder even for pushed routes); pop when
                  // poppable, else fall back to the event detail.
                  onBack: () => popOrGo(context, '/memberzone/events/$eventId'),
                  onOpenReview: (id) => context.push(reviewEditPath(id)),
                ),
              );
            },
          ),
          GoRoute(
            path: '/memberzone/events/:eventId/:occurrenceTimeUtc/attendance',
            pageBuilder: (context, state) {
              final eventId = int.parse(state.pathParameters['eventId']!);
              final occurrenceTimeUtc = DateTime.parse(
                state.pathParameters['occurrenceTimeUtc']!,
              );
              final notifParam = state.uri.queryParameters['notif'];
              final sourceNotificationId = notifParam == null
                  ? null
                  : int.tryParse(notifParam);
              return NoTransitionPage(
                child: EventOccurencesAttendanceScreen(
                  eventId: eventId,
                  occurrenceTimeUtc: occurrenceTimeUtc,
                  sourceNotificationId: sourceNotificationId,
                  onHome: () => context.go('/'),
                  onDismissed: () => popOrGo(context, '/'),
                  // Always show a back button (canPop() reads false inside the
                  // shell pageBuilder even for pushed routes); pop when
                  // poppable, else fall back to the dashboard.
                  onBack: () => popOrGo(context, '/'),
                ),
              );
            },
          ),
          GoRoute(
            path: '/memberzone/credit/:targetUsername',
            pageBuilder: (context, state) => NoTransitionPage(
              child: CreditScreen(
                targetUsername: state.pathParameters['targetUsername']!,
                onHome: () => context.go('/'),
                onBack: () => popOrGo(context, '/'),
              ),
            ),
          ),
          GoRoute(
            path: '/memberzone/profile',
            pageBuilder: (context, state) => NoTransitionPage(
              child: ProfileScreen(
                eventsSection: (u) => MyEventsSection(
                  username: u,
                  onEventTap: (event) => GoRouter.of(
                    context,
                  ).push('/memberzone/my-events/$u/${event.id}'),
                ),
                onBack: context.canPop() ? () => context.pop() : null,
              ),
            ),
          ),
          ...reviewRoutes(),
          GoRoute(
            path: '/memberzone/contact',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ContactScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});
