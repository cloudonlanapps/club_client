import 'package:cl_club_events/cl_club_events.dart'
    show MyEventDetailsView, RemovedEventView;
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clMyEventDetailProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show ServerException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ErrorTone, ErrorView, LoadingView;

import '../permissions/my_events_access.dart';

/// My-event details screen at
/// `/memberzone/my-events/:targetUsername/:eventId`.
class MyEventDetailsScreen extends ConsumerWidget {
  const MyEventDetailsScreen({
    required this.targetUsername,
    required this.eventId,
    required this.onHome,
    required this.onDismissed,
    this.sourceNotificationId,
    this.onVenueTap,
    this.onPublicProfileTap,
    this.onBack,
    super.key,
  });

  final String targetUsername;
  final int eventId;
  final int? sourceNotificationId;
  final ValueChanged<int>? onVenueTap;

  /// Opens a coach's public profile by `publicId` (member-facing preview).
  final ValueChanged<String>? onPublicProfileTap;
  final VoidCallback onHome;

  /// Leaves this page when the event no longer exists. Wired from the router.
  final VoidCallback onDismissed;
  final VoidCallback? onBack;

  Widget _accessDenied({String? subtitle}) {
    return ErrorView(
      tone: ErrorTone.neutral,
      icon: LucideIcons.shieldAlert,
      title: 'Access Denied',
      subtitle: subtitle ?? 'You do not have permission to view this page.',
      onHome: onHome,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(myEventsAccessProvider(targetUsername));
    return accessAsync.when(
      loading: () => const LoadingView(),
      error: (_, _) => _accessDenied(),
      data: (allowed) {
        if (!allowed) return _accessDenied();
        final user = ref.watch(authStateProvider).valueOrNull;
        if (user == null) return _accessDenied();

        final detailKey = (username: targetUsername, eventId: eventId);
        final eventAsync = ref.watch(clMyEventDetailProvider(detailKey));
        return eventAsync.when(
          loading: () => const LoadingView(),
          error: (error, _) {
            if (error is ServerException && error.statusCode == 404) {
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
              onRetry: () => ref.invalidate(clMyEventDetailProvider(detailKey)),
            );
          },
          data: (_) => MyEventDetailsView(
            currentUser: user,
            targetUsername: targetUsername,
            eventId: eventId,
            onVenueTap: onVenueTap,
            onPublicProfileTap: onPublicProfileTap,
            onBack: onBack,
          ),
        );
      },
    );
  }
}
