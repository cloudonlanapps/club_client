import 'package:flutter/material.dart';

import 'admin_user_review_form_data.dart';
import 'admin_user_review_page.dart';

/// Pure UI form for admin pending-user review of a single user.
///
/// No Riverpod, no SDK dependency — the host supplies the data and the
/// three action callbacks. Used to be a multi-user PageView; the per-user
/// state-bleed issues that came with that were unworkable, so this is now
/// single-user only and the host navigates back to pick another user.
///
/// The host receives the admin's decision through one of three callbacks:
///
/// ```dart
/// onApprove(data, reason)   // reason: trimmed text, or null when empty
/// onReject(data, reason)    // reason: trimmed text, or null when empty
/// onBlock(data, reason)     // reason: trimmed text, or null when empty
/// ```
///
/// While any callback future is pending, the page's controls disable and
/// the Confirm button reads "Working…". If the future throws, the form
/// re-enables its controls and keeps the selection so the admin can retry
/// — it does not surface its own error UI.
class AdminUserReviewForm extends StatelessWidget {
  const AdminUserReviewForm({
    required this.data,
    required this.onApprove,
    required this.onReject,
    required this.onBlock,
    super.key,
    this.httpHeaders = const {},
    this.showDocuments = true,
  });

  /// Whether the page shows the identity-documents section. Off where the
  /// server does not verify identity (#84): there is nothing to review, and
  /// an empty "No documents on file." box would read as something missing.
  final bool showDocuments;

  final AdminUserReviewFormData data;
  final AdminUserReviewActionCallback onApprove;
  final AdminUserReviewActionCallback onReject;
  final AdminUserReviewActionCallback onBlock;

  /// HTTP headers forwarded to identity-document preview image requests.
  ///
  /// Populate from `imageAuthHeadersProvider` (in `cl_member_auth`) when
  /// the host's URIs may require authentication.
  final Map<String, String> httpHeaders;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;
        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 600.0 : double.infinity,
            ),
            child: AdminUserReviewPage(
              key: ValueKey('admin-review-${data.userKey}'),
              data: data,
              onApprove: onApprove,
              onReject: onReject,
              onBlock: onBlock,
              httpHeaders: httpHeaders,
              showDocuments: showDocuments,
            ),
          ),
        );
      },
    );
  }
}
