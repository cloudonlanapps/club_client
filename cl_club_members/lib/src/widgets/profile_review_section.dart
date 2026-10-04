import 'dart:async';

import 'package:cl_club_evaluation/cl_club_evaluation.dart'
    show showStartReviewDialog;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The *Reviews* section of a member's profile, for a coach
/// (club_core#174, design 4.3): **Add Review** starts a review of
/// [username] and hands the new draft's id to [onOpenReview].
///
/// The profile renders it only for a coach viewing another member while
/// the server runs evaluations; the section itself does not gate.
class ProfileReviewSection extends StatelessWidget {
  /// A section for [coach] reviewing [username].
  const ProfileReviewSection({
    required this.coach,
    required this.username,
    this.onOpenReview,
    super.key,
  });

  /// The section's title.
  static const title = 'Reviews';

  /// What the section offers.
  static const description =
      'Start a review of this member from one of your templates.';

  /// The button's label.
  static const addReviewLabel = 'Add Review';

  /// Padding inside the card.
  static const padding = 20.0;

  /// The coach viewing the profile.
  final UserPrivate coach;

  /// The member the profile is about.
  final String username;

  /// Opens the new draft; when null the draft is only created.
  final ValueChanged<int>? onOpenReview;

  /// Opens the start dialog with the member fixed, then the new draft.
  Future<void> addReview(BuildContext context) async {
    final id = await showStartReviewDialog(
      context: context,
      currentUser: coach,
      username: username,
    );
    if (id != null) onOpenReview?.call(id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadCard(
      padding: const EdgeInsets.all(padding),
      title: Text(title, style: theme.textTheme.h4),
      description: const Text(description),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: ShadButton.outline(
          leading: const Icon(LucideIcons.clipboardPen),
          onPressed: () => unawaited(addReview(context)),
          child: const Text(addReviewLabel),
        ),
      ),
    );
  }
}
