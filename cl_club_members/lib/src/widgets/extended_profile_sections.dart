import 'package:cl_club_members/src/widgets/background_card.dart';
import 'package:cl_club_members/src/widgets/guardian_card.dart';
import 'package:cl_club_members/src/widgets/sports_details_card.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show extendedProfileProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The extended profile's three sections, one under the other: Sports
/// details, Background and Guardian (club_client#320). Each edits in place
/// and saves its own fields.
///
/// Renders nothing unless the server reports the extended profile on
/// ([extendedProfileProvider]); an unknown answer shows nothing either.
/// Used on a member's profile and in onboarding's optional step, where the
/// host decides who sees it and passes [canEdit].
class ExtendedProfileSections extends ConsumerWidget {
  const ExtendedProfileSections({
    required this.user,
    required this.canEdit,
    super.key,
  });

  /// Gap between two sections.
  static const double sectionGap = 20;

  /// The member whose sections these are.
  final UserPrivate user;

  /// Whether the viewer may edit them.
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(extendedProfileProvider) != true) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: sectionGap,
      children: [
        SportsDetailsCard(user: user, canEdit: canEdit),
        BackgroundCard(user: user, canEdit: canEdit),
        GuardianCard(user: user, canEdit: canEdit),
      ],
    );
  }
}
