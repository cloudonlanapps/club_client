import 'dart:async';

import 'package:cl_club_evaluation/cl_club_evaluation.dart'
    show showStartReviewDialog;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;
import 'package:ui_lib/ui_lib.dart' show ActionItem;

/// Label of the enrolment row's review action (club_core#174).
const String enrollmentAddReviewLabel = 'Add Review';

/// The **Add Review** action on [username]'s row of event [eventId]
/// (club_core#174, design 4.3): the start dialog with the member and the
/// event fixed, then [onOpenReview] with the new draft's id.
///
/// Offered to a coach; the caller decides that.
ActionItem enrollmentReviewAction({
  required BuildContext context,
  required UserPrivate coach,
  required String username,
  required int eventId,
  ValueChanged<int>? onOpenReview,
}) => ActionItem(
  label: enrollmentAddReviewLabel,
  icon: LucideIcons.clipboardPen,
  onPressed: () => unawaited(() async {
    final id = await showStartReviewDialog(
      context: context,
      currentUser: coach,
      username: username,
      eventId: eventId,
    );
    if (id != null) onOpenReview?.call(id);
  }()),
);
