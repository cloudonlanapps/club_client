import 'package:cl_club_members/src/widgets/avatar_upload_affordance.dart';
import 'package:cl_club_members/src/widgets/avatar_visibility_toggle.dart';
import 'package:cl_club_members/src/widgets/profile_role_stamps.dart';
import 'package:cl_club_members/src/widgets/user_avatar.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The photo side of the profile card: the avatar with the role stamps over
/// it, the pencil that changes it, and the member's visibility tick.
///
/// Who gets what (club_client#35):
///
/// - the member themselves: the pencil, and under the photo the "Allow
///   others to see my photo" tick for the current photo;
/// - an admin on another member who is not deleted: the pencil, which
///   uploads on the member's behalf, private, with no tick anywhere;
/// - a coach or another member: neither.
class ProfileAvatarArea extends ConsumerWidget {
  /// Creates the photo area for [user].
  const ProfileAvatarArea({required this.user, super.key});

  /// The member whose profile is shown.
  final UserInfo user;

  /// Inset of the overlays from the photo's edges.
  static const double overlayInset = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewer = ref.watch(authStateProvider).valueOrNull;
    final isSelf = viewer != null && viewer.username == user.username;
    // The server refuses an upload in a deleted user's name.
    final onBehalf =
        !isSelf && (viewer?.isAdmin ?? false) && user.deletedAtUtc == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: UserAvatar(user: user)),
              Positioned(
                right: overlayInset,
                bottom: overlayInset,
                child: ProfileRoleStamps(user: user),
              ),
              if (isSelf || onBehalf)
                Positioned(
                  top: overlayInset,
                  right: overlayInset,
                  child: AvatarUploadAffordance(
                    username: user.username,
                    onBehalf: onBehalf,
                  ),
                ),
            ],
          ),
        ),
        if (isSelf) AvatarVisibilityToggle(username: user.username),
      ],
    );
  }
}
