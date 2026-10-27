import 'package:cl_club_members/src/utils/admin_user_profile_saves.dart'
    show adminSaveUserField;
import 'package:cl_club_members/src/widgets/profile_detail_cards.dart';
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The signed-in member's own profile cards, every one editable
/// (club_client#340): the profile card with bio and achievements, personal
/// details, contact, address and, while the server has the extended
/// profile on, its sections.
///
/// Onboarding's profile page shows it to a `pending` member, whose profile
/// the member zone does not show yet. Each card saves its own fields, and
/// the saved member becomes the session's, so the host
/// rebuilds it from `authStateProvider` with what was saved.
class OwnProfileCards extends ConsumerWidget {
  const OwnProfileCards({required this.user, super.key});

  /// The signed-in member.
  final UserPrivate user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final username = user.username;
    return ProfileDetailCards(
      user: user,
      canEdit: true,
      showExtended: true,
      onBioSave: (bio) =>
          adminSaveUserField(ref, context, username, bio: () => bio),
      onAchievementsSave: (achievements) => adminSaveUserField(
        ref,
        context,
        username,
        achievements: () => achievements,
      ),
    );
  }
}
