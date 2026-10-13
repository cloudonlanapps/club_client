import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show PickerUser;

import 'event_read_coach_row.dart';

/// Read mode of the Organizer & coaches section: the organizer, then each
/// coach on a row of their own. A coach who has opted into a public profile
/// is a link to it; the others are plain text.
class OrganizerCoachesRead extends StatelessWidget {
  /// Shows [organizer] and [coaches].
  const OrganizerCoachesRead({
    required this.organizer,
    required this.coaches,
    required this.master,
    this.onPublicProfileTap,
    super.key,
  });

  /// The organizer, or `null` when the event has none.
  final PickerUser? organizer;

  /// The coaches, in the event's order.
  final List<PickerUser> coaches;

  /// The users master, which says who has a public profile; `null` while
  /// it loads.
  final Map<String, UserInfo>? master;

  /// Opens a coach's public profile by `publicId`.
  final ValueChanged<String>? onPublicProfileTap;

  /// Tap handler that opens a coach's public profile — non-null (tappable)
  /// only when the coach has opted into a public profile.
  VoidCallback? publicProfileTapFor(String username) {
    final info = master?[username];
    final onTap = onPublicProfileTap;
    if (info == null || !info.isPublicProfile || onTap == null) return null;
    return () => onTap(info.publicId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Organizer', style: theme.textTheme.small),
        const SizedBox(height: 4),
        Text(
          organizer?.displayName ?? 'Unassigned',
          style: theme.textTheme.p,
        ),
        const SizedBox(height: 12),
        Text('Coaches', style: theme.textTheme.small),
        const SizedBox(height: 4),
        if (coaches.isEmpty)
          Text('No coaches assigned.', style: theme.textTheme.muted)
        else
          for (final coach in coaches)
            EventReadCoachRow(
              coach: coach,
              onTap: publicProfileTapFor(coach.username),
            ),
      ],
    );
  }
}
