import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Shown in place of a profile the viewer may not see: a member who is not
/// active, to anyone but an admin.
class ProfileUnavailable extends StatelessWidget {
  /// The notice.
  const ProfileUnavailable({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.userX,
            size: 48,
            color: theme.colorScheme.mutedForeground,
          ),
          const SizedBox(height: 12),
          Text('Profile Unavailable', style: theme.textTheme.h4),
          const SizedBox(height: 4),
          Text(
            'This user profile is not available.',
            style: theme.textTheme.muted,
          ),
        ],
      ),
    );
  }
}
