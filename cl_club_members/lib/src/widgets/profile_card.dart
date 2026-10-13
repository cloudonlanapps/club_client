import 'package:cl_club_members/src/widgets/profile_avatar_area.dart';
import 'package:cl_club_members/src/widgets/profile_content_area.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Main profile card — mirrors CoachCard layout.
///
/// Desktop: avatar image on the left, content on the right.
/// Mobile: avatar image on top, content below.
class ProfileCard extends ConsumerWidget {
  const ProfileCard({
    required this.user,
    required this.isMobile,
    this.onBioSave,
    this.onAchievementsSave,
    super.key,
  });

  final UserInfo user;
  final bool isMobile;

  /// Called with updated bio markdown. If null, bio is not editable.
  final ValueChanged<String>? onBioSave;

  /// Called with updated achievements markdown. If null, achievements is not
  /// editable.
  final ValueChanged<String>? onAchievementsSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final avatarWidget = ProfileAvatarArea(user: user);
    final contentWidget = ProfileContentArea(
      user: user,
      onBioSave: onBioSave,
      onAchievementsSave: onAchievementsSave,
    );

    if (isMobile) {
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 240,
                  child: avatarWidget,
                ),
              ),
            ),
            contentWidget,
          ],
        ),
      );
    }

    // Desktop: image on the left, content on the right.
    //
    // IntrinsicHeight forces the Row to size to the taller child's height,
    // and CrossAxisAlignment.stretch then makes the avatar column take that
    // full height. UserAvatar is built to fill its parent, so it scales the
    // image with BoxFit.cover.
    return Container(
      constraints: const BoxConstraints(minHeight: 300),
      decoration: BoxDecoration(
        color: theme.colorScheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 260, child: avatarWidget),
            Expanded(child: contentWidget),
          ],
        ),
      ),
    );
  }
}
