import 'package:cl_club_members/src/widgets/profile_credit_line.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EditableMarkdown, ThemedMarkdown;

/// Content area: name, status, roles, bio, achievements.
class ProfileContentArea extends ConsumerWidget {
  const ProfileContentArea({
    required this.user,
    this.onBioSave,
    this.onAchievementsSave,
    super.key,
  });

  final UserInfo user;

  /// Called with updated bio markdown. If null, bio is not editable.
  final ValueChanged<String>? onBioSave;

  /// Called with updated achievements markdown. If null, achievements is not
  /// editable.
  final ValueChanged<String>? onAchievementsSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Role stamps overlay the avatar (see ProfileRoleStamps).
          // Name / username live in Contact & Details below; where credit
          // is on, the name leads the card with the member's credit.
          ProfileCreditLine(user: user),
          // Bio
          if (onBioSave != null) ...[
            EditableMarkdown(
              data: user.bio ?? '',
              label: 'Bio',
              emptyText: 'Tap to add bio',
              onSave: onBioSave!,
            ),
            const SizedBox(height: 24),
          ] else if (user.bio != null && user.bio!.isNotEmpty) ...[
            ThemedMarkdown(data: user.bio!, textAlign: TextAlign.justify),
            const SizedBox(height: 24),
          ],
          // Achievements
          if (onAchievementsSave != null) ...[
            Text('Achievements', style: theme.textTheme.h4),
            const SizedBox(height: 8),
            EditableMarkdown(
              data: user.achievements ?? '',
              label: 'Achievements',
              emptyText: 'Tap to add achievements',
              onSave: onAchievementsSave!,
            ),
          ] else if (user.achievements != null &&
              user.achievements!.isNotEmpty) ...[
            Text('Achievements', style: theme.textTheme.h4),
            const SizedBox(height: 8),
            ThemedMarkdown(
              data: user.achievements!,
              textAlign: TextAlign.justify,
            ),
          ],
        ],
      ),
    );
  }
}
