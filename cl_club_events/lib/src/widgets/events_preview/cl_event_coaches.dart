import 'package:cl_remote_store/cl_remote_store.dart' show clUserInfoProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show Event;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Read-only Organizer & Coaches section for the member event preview.
///
/// Mirrors the admin editor's read layout, but resolves coach display names
/// via the member-accessible [clUserInfoProvider] (`getUserInfo`) rather than
/// the admin-only users master. A coach name is tappable only when the coach
/// is a publicly-surfaced profile (`isPublicProfile`); the tap forwards the
/// coach's `publicId` to [onPublicProfileTap] so the host can open the
/// public profile route.
class ClEventCoaches extends StatelessWidget {
  const ClEventCoaches({
    required this.event,
    this.onPublicProfileTap,
    super.key,
  });

  final Event event;

  /// Called with a coach's `publicId` when their (surfaced) name is tapped.
  final ValueChanged<String>? onPublicProfileTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final organizerName = event.organizerName?.trim() ?? '';
    final coachNames = event.coachNames ?? const <String>[];

    if (organizerName.isEmpty && coachNames.isEmpty) {
      return const SizedBox.shrink();
    }

    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.users,
                size: 16,
                color: theme.colorScheme.mutedForeground,
              ),
              const SizedBox(width: 8),
              Text('Organizer & Coaches', style: theme.textTheme.h4),
            ],
          ),
          const SizedBox(height: 12),
          Text('Organizer', style: theme.textTheme.small),
          const SizedBox(height: 4),
          Text(
            organizerName.isEmpty ? 'Unassigned' : organizerName,
            style: theme.textTheme.p,
          ),
          const SizedBox(height: 12),
          Text('Coaches', style: theme.textTheme.small),
          const SizedBox(height: 4),
          if (coachNames.isEmpty)
            Text('No coaches assigned.', style: theme.textTheme.muted)
          else
            for (final username in coachNames)
              _CoachRow(
                username: username,
                onPublicProfileTap: onPublicProfileTap,
              ),
        ],
      ),
    );
  }
}

/// One coach row, resolving the display name (and public-profile eligibility)
/// from [clUserInfoProvider].
class _CoachRow extends ConsumerWidget {
  const _CoachRow({required this.username, this.onPublicProfileTap});

  final String username;
  final ValueChanged<String>? onPublicProfileTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final info = ref.watch(clUserInfoProvider(username));

    // Until resolved (or on error), show the raw username, non-tappable.
    final user = info.valueOrNull;
    final label = user?.displayName ?? username;
    final row = Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text('• $label', style: theme.textTheme.p),
    );

    final tappable =
        user != null && user.isPublicProfile && onPublicProfileTap != null;
    if (!tappable) return row;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onPublicProfileTap!(user.publicId),
      child: MouseRegion(cursor: SystemMouseCursors.click, child: row),
    );
  }
}
