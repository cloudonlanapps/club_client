// Issue 113: while a request is approved, the Manage Requests dialog is
// closed by nothing.
import 'dart:async';

import 'package:cl_club_events/src/widgets/cards/actions/manage_requests_dialog.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/credit_scope.dart';
import '../../support/dialog_dismissal.dart';

/// Enrollments whose approval waits on [held].
class _HeldEnrollments extends ClEnrollmentsMasterNotifier {
  _HeldEnrollments(this.held);

  final Completer<void> held;

  /// The members approved.
  final List<String> approved = [];

  @override
  Future<Map<String, EnrollmentStatus>> build(int arg) async => const {};

  @override
  Future<void> approveRequest(String username) async {
    approved.add(username);
    await held.future;
  }
}

void main() {
  testWidgets('Issue 113: while Manage Requests approves a request, the X, '
      'a tap outside, Escape and system back do not close it', (tester) async {
    final enrollments = _HeldEnrollments(Completer<void>());
    var completed = 0;
    await tester.pumpWidget(
      creditScope(
        creditSystem: false,
        extra: [
          clEnrollmentsMasterProvider.overrideWith(() => enrollments),
          avatarImageProvider.overrideWith((ref, username) async => null),
          imageAuthHeadersProvider.overrideWith((ref) async => const {}),
        ],
        child: Builder(
          builder: (context) => ShadButton(
            onPressed: () => showShadDialog<void>(
              context: context,
              builder: (_) => ManageRequestsDialog(
                eventId: campId,
                requestingUsers: const ['ana'],
                onComplete: () => completed++,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('approve-request-ana')));
    await tester.pump();
    expect(enrollments.approved, ['ana']);

    await expectNoDismissal(tester, find.byType(ManageRequestsDialog));
    expect(completed, 0);

    enrollments.held.complete();
    await tester.pumpAndSettle();
    expect(find.byType(ManageRequestsDialog), findsNothing);
    expect(completed, 1);
  });
}
