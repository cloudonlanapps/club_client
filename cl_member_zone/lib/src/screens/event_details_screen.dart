import 'package:cl_club_events/cl_club_events.dart'
    show EventDetailsView, RemovedEventView;
import 'package:cl_member_auth/cl_member_auth.dart'
    show authStateProvider, userAllowedForEvents;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventDetailProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorTone, ErrorView, LoadingView;

import '../utils/master_errors.dart';

/// Event details screen at `/memberzone/events/:eventId`.
class EventDetailsScreen extends ConsumerWidget {
  const EventDetailsScreen({
    required this.eventId,
    required this.onNavigateToEvent,
    required this.onHome,
    required this.onDismissed,
    this.sourceNotificationId,
    this.onEdit,
    this.onDeleted,
    this.onManageEnrolments,
    this.onMemberTap,
    this.onPublicProfileTap,
    this.onBack,
    this.onHistory,
    super.key,
  });

  final int eventId;
  final int? sourceNotificationId;

  /// Replaces the current event-detail route with another event id.
  final ValueChanged<int> onNavigateToEvent;
  final VoidCallback onHome;

  /// Leaves this page when the event no longer exists. Wired from the router.
  final VoidCallback onDismissed;
  final VoidCallback? onEdit;

  /// Leaves this page once the event has been deleted from Event
  /// Management. Wired from the router.
  final VoidCallback? onDeleted;
  final ValueChanged<int>? onManageEnrolments;
  final ValueChanged<String>? onMemberTap;

  /// Opens a coach's public profile by `publicId` (member-facing preview).
  final ValueChanged<String>? onPublicProfileTap;

  /// Pops the route when poppable (deep-link entry), `null` otherwise.
  /// Supplied by the router so the view's back button visibility matches
  /// how the screen was reached.
  final VoidCallback? onBack;

  /// Opens the event's audit history (admin-only affordance, issue #207).
  final VoidCallback? onHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (!userAllowedForEvents(user)) {
      return ErrorView(
        tone: ErrorTone.neutral,
        icon: LucideIcons.shieldAlert,
        title: 'Access Denied',
        subtitle: 'You do not have permission to view this page.',
        onHome: onHome,
      );
    }

    final eventAsync = ref.watch(clEventDetailProvider(eventId));
    return eventAsync.when(
      loading: () => const LoadingView(),
      error: (error, _) {
        if (isMasterNotFoundError(error)) {
          return RemovedEventView(
            eventId: eventId,
            sourceNotificationId: sourceNotificationId,
            onDismissed: onDismissed,
          );
        }
        return ErrorView(
          title: 'Could not load event',
          errorCode: '$error',
          onHome: onHome,
          onRetry: () => ref.invalidate(clEventDetailProvider(eventId)),
        );
      },
      data: (event) {
        return EventDetailsView(
          currentUser: user!,
          eventId: eventId,
          onManageEnrolments: onManageEnrolments,
          onMemberTap: onMemberTap,
          onPublicProfileTap: onPublicProfileTap,
          onBack: onBack,
          onHistory: onHistory,
          onDeleted: onDeleted,
        );
      },
    );
  }
}
