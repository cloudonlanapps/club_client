import 'package:cl_club_members/src/widgets/address_card.dart';
import 'package:cl_club_members/src/widgets/extended_profile_sections.dart';
import 'package:cl_club_members/src/widgets/personal_details_card.dart';
import 'package:cl_club_members/src/widgets/profile_card.dart';
import 'package:cl_club_members/src/widgets/user_contact_info_card.dart';
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/material.dart';

/// A member's profile cards, one under the other, in the profile's order:
/// the profile card, personal details, contact, address and, when
/// [showExtended], the extended profile's sections (club_client#320).
///
/// The member's profile shows them, and so does onboarding's profile page
/// through `OwnProfileCards` (club_client#340). The host decides who may
/// edit them ([canEdit]) and who sees the extended sections.
class ProfileDetailCards extends StatelessWidget {
  const ProfileDetailCards({
    required this.user,
    required this.canEdit,
    required this.showExtended,
    this.onBioSave,
    this.onAchievementsSave,
    super.key,
  });

  /// Below this width the profile card stacks its photo over its text.
  static const double mobileWidth = 700;

  /// Gap between two cards.
  static const double gap = 20;

  /// The member whose cards these are.
  final UserPrivate user;

  /// Whether the viewer may edit the sections.
  final bool canEdit;

  /// Whether the extended profile's sections are shown at all; they still
  /// render nothing while the server has the extended profile off.
  final bool showExtended;

  /// Called with updated bio markdown. If null, bio is not editable.
  final ValueChanged<String>? onBioSave;

  /// Called with updated achievements markdown. If null, achievements is
  /// not editable.
  final ValueChanged<String>? onAchievementsSave;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < mobileWidth;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileCard(
          user: user,
          isMobile: isMobile,
          onBioSave: onBioSave,
          onAchievementsSave: onAchievementsSave,
        ),
        const SizedBox(height: gap),
        PersonalDetailsCard(user: user, canEdit: canEdit),
        const SizedBox(height: gap),
        UserContactInfoCard(user: user, canEdit: canEdit),
        const SizedBox(height: gap),
        AddressCard(user: user, canEdit: canEdit),
        if (showExtended) ...[
          const SizedBox(height: gap),
          ExtendedProfileSections(user: user, canEdit: canEdit),
        ],
      ],
    );
  }
}
