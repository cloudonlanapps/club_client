import 'package:cl_remote_store/cl_remote_store.dart'
    show clMyEventDetailProvider, clVenueDetailProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart' show LoadingView, TitleRow;

import '../widgets/buttons/enrollment_action_buttons.dart';
import '../widgets/events_preview/cl_event_preview.dart';
import '../widgets/my_enrollment_status_line.dart';

class MyEventDetailsView extends ConsumerWidget {
  const MyEventDetailsView({
    required this.currentUser,
    required this.targetUsername,
    required this.eventId,
    this.onVenueTap,
    this.onPublicProfileTap,
    this.onBack,
    super.key,
  });

  final UserPrivate currentUser;

  /// The user whose enrollment for this event is being viewed/acted on.
  /// May differ from [currentUser] when an admin or coach views a member.
  final String targetUsername;

  final int eventId;
  final ValueChanged<int>? onVenueTap;

  /// Called with a coach's `publicId` when their (surfaced) name is tapped.
  final ValueChanged<String>? onPublicProfileTap;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(
      clMyEventDetailProvider((username: targetUsername, eventId: eventId)),
    );
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
            TitleRow(title: event.title, onBack: onBack),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClEventPreview(
                      event: event,
                      venue: venue,
                      onVenueTap: onVenueTap,
                      onPublicProfileTap: onPublicProfileTap,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: MyEnrollmentStatusLine(
                              username: targetUsername,
                              eventId: event.id,
                              eventType: event.type,
                            ),
                          ),
                          const SizedBox(width: 8),
                          EnrollmentActionButtons(
                            username: targetUsername,
                            eventId: event.id,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
