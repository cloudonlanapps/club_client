import 'package:flutter/foundation.dart';
import 'package:ui_lib/src/widgets/admin_user_review/admin_user_review_form.dart'
    show AdminUserReviewForm;
import 'package:ui_lib/ui_lib.dart' show AdminUserReviewForm;

import '../identity_documents/identity_document_slot.dart';

/// One of the three admin decisions on a pending user.
enum AdminUserReviewAction { approve, reject, block }

/// Flat record describing the pending user under review. The host builds
/// one of these and passes it to [AdminUserReviewForm]; the form never
/// reaches back into a Riverpod / SDK layer.
@immutable
class AdminUserReviewFormData {
  const AdminUserReviewFormData({
    required this.userKey,
    required this.fullName,
    required this.userName,
    required this.dateOfBirth,
    required this.gender,
    required this.documents,
    this.adminReviewNote,
  });

  /// Opaque identifier — the form passes this back unchanged via the action
  /// callbacks so the host can locate the underlying user record.
  final String userKey;

  final String fullName;

  /// User handle / login name. Rendered as the tile subtitle and embedded in
  /// the Block button label.
  final String userName;

  final DateTime dateOfBirth;
  final String gender;
  final List<IdentityDocumentSlot> documents;

  /// Most recent admin review note still attached to the user (if any). When
  /// non-null, the form renders it as a muted callout above the action row so
  /// the reviewer can see what the prior admin asked for.
  final String? adminReviewNote;
}

/// Host callback fired when the admin confirms an action. The future drives
/// the form's submitting state — while it is pending, all controls disable
/// and the Confirm button reads "Working…". If the future throws, the form
/// re-enables its controls and keeps the current selection so the admin can
/// retry. The form does not surface its own error UI.
///
/// [reason] is the trimmed contents of the Reason field. For Reject and
/// Block it is guaranteed non-null and 10–500 chars (the form gates Confirm
/// on that). For Approve it is null when the field was left blank, otherwise
/// the trimmed contents.
typedef AdminUserReviewActionCallback =
    Future<void> Function(AdminUserReviewFormData data, String? reason);
