import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

/// Demo screen for [AdminUserReviewForm].
///
/// Fakes a single pending user with picsum thumbnails so the selection
/// behaviour and submitting state are visible without a real backend.
class AdminUserReviewFormScreen extends StatefulWidget {
  const AdminUserReviewFormScreen({super.key});

  @override
  State<AdminUserReviewFormScreen> createState() =>
      _AdminUserReviewFormScreenState();
}

class _AdminUserReviewFormScreenState extends State<AdminUserReviewFormScreen> {
  static final AdminUserReviewFormData _user = AdminUserReviewFormData(
    userKey: 'demo-asha',
    fullName: 'Asha Verma',
    userName: 'asha.verma',
    dateOfBirth: DateTime(1998, 3, 14),
    gender: 'Female',
    documents: [
      const IdentityDocumentSlot(
        id: 'demo-asha-1',
        uri: 'https://picsum.photos/seed/asha-1/640/400',
        mimeType: 'image/jpeg',
        sizeBytes: 124000,
        fileName: 'aadhaar-front.jpg',
      ),
      const IdentityDocumentSlot(
        id: 'demo-asha-2',
        uri: 'https://picsum.photos/seed/asha-2/640/400',
        mimeType: 'image/jpeg',
        sizeBytes: 119000,
        fileName: 'aadhaar-back.jpg',
      ),
    ],
    adminReviewNote:
        'New submission — looks complete. Verify DOB matches the document.',
  );

  Future<void> _fakeAction(
    String label,
    AdminUserReviewFormData data,
    String? reason,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final reasonLine = reason == null ? '' : '  —  reason: $reason';
    ShadToaster.of(context).show(
      ShadToast(description: Text('$label "${data.fullName}".$reasonLine')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminUserReviewForm(
      data: _user,
      onApprove: (data, reason) => _fakeAction('Approved', data, reason),
      onReject: (data, reason) => _fakeAction('Rejected', data, reason),
      onBlock: (data, reason) => _fakeAction('Blocked', data, reason),
    );
  }
}
