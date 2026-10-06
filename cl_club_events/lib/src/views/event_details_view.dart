import 'package:cl_member_auth/cl_member_auth.dart' show canManageEvent;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEventDetailProvider, clVenueDetailProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart' show LoadingView, TitleRow;

import '../widgets/event_editor/archived_event_body.dart';
import '../widgets/event_editor/editable_event_body.dart';
import '../widgets/events_preview/cl_event_preview.dart';

/// Event detail view. Whoever may manage the event — an admin or its
/// organizer ([canManageEvent], as the server's `require_organizer_or_admin`)
/// — gets the inline section editors ([EditableEventBody]); every other
/// coach gets the read-only [ClEventPreview] (club_core#150).
///
/// An archived event, which only an admin can load, is read-only apart from
/// its Event Management card ([ArchivedEventBody], club_client#36).
class EventDetailsView extends ConsumerWidget {
  const EventDetailsView({
    required this.currentUser,
    required this.eventId,
    this.onVenueTap,
    this.onManageEnrolments,
    this.onMemberTap,
    this.onPublicProfileTap,
    this.onBack,
    this.onHistory,
    this.onDeleted,
    super.key,
  });

  final UserPrivate currentUser;
  final int eventId;
  final ValueChanged<int>? onVenueTap;
  final ValueChanged<int>? onManageEnrolments;
  final ValueChanged<String>? onMemberTap;

  /// Called with a coach's `publicId` when their name is tapped in the
  /// read-only (non-admin) preview, so the host can open the public profile.
  final ValueChanged<String>? onPublicProfileTap;
  final VoidCallback? onBack;

  /// Opens the event's audit history. The title-row affordance is shown only
  /// to admins (issue #207).
  final VoidCallback? onHistory;

  /// Leaves the page once the event has been deleted from Event Management.
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(
      currentUser.isCoachOrAdmin,
      'EventDetailsView called for ${currentUser.username}, who is neither '
      'a coach nor an admin. Screen gate failed.',
    );
    final eventAsync = ref.watch(clEventDetailProvider(eventId));
    return eventAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => Center(child: Text('Failed to load event: $e')),
      data: (event) {
        final venue = ref
            .watch(clVenueDetailProvider(event.venueId))
            .whenOrNull(data: (v) => v);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitleRow(
              title: event.title,
              onBack: onBack,
              onHistory: currentUser.isAdmin ? onHistory : null,
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                child: !event.isActive
                    ? ArchivedEventBody(
                        event: event,
                        currentUser: currentUser,
                        venue: venue,
                        onVenueTap: onVenueTap,
                        onPublicProfileTap: onPublicProfileTap,
                        onDeleted: onDeleted,
                      )
                    : canManageEvent(event, currentUser)
                    ? EditableEventBody(
                        event: event,
                        currentUser: currentUser,
                        venue: venue,
                        onVenueTap: onVenueTap,
                        onManageEnrolments: onManageEnrolments,
                        onMemberTap: onMemberTap,
                        onPublicProfileTap: onPublicProfileTap,
                        onDeleted: onDeleted,
                      )
                    : ClEventPreview(
                        event: event,
                        currentUser: currentUser,
                        venue: venue,
                        onVenueTap: onVenueTap,
                        onManageEnrolments: onManageEnrolments,
                        onMemberTap: onMemberTap,
                        onPublicProfileTap: onPublicProfileTap,
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
