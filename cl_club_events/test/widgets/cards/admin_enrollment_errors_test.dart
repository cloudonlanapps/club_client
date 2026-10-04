import 'package:cl_club_events/src/widgets/cards/actions/admin_enrollment_actions.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/widgets.dart' show Text;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton, ActionGroup;

import '../../support/credit_scope.dart';

/// Refuses every approval and removal with [code].
class _Refusing extends ClEnrollmentsMasterNotifier {
  _Refusing(this.code);
  final String code;

  @override
  Future<Map<String, EnrollmentStatus>> build(int arg) async => const {};

  ServerException get refusal =>
      ServerException(statusCode: 409, code: code, message: 'raw');

  @override
  Future<void> approveRequest(String username) async => throw refusal;

  @override
  Future<void> removeEnrollment(String username, {String? reason}) async =>
      throw refusal;
}

Future<void> _pump(
  WidgetTester tester, {
  required EnrollmentStatus status,
  required String code,
}) async {
  await tester.pumpWidget(
    creditScope(
      creditSystem: false,
      extra: [clEnrollmentsMasterProvider.overrideWith(() => _Refusing(code))],
      child: AdminEnrollmentActions(
        eventId: campId,
        username: 'row_member',
        status: status,
        displayName: 'Row Member',
        builder: (context, actions) => ActionGroup(actions: actions),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ActionButton _button(WidgetTester tester, String label) =>
    tester.widget<ActionButton>(find.widgetWithText(ActionButton, label));

void main() {
  testWidgets('Issue 128: a clashing approval toasts the clash', (
    tester,
  ) async {
    await _pump(
      tester,
      status: EnrollmentStatus.requested,
      code: SdkErrorCode.timeConflict,
    );
    _button(tester, 'Approve').onPressed!();
    await tester.pumpAndSettle();
    expect(
      find.text(
        'This member is already enrolled in an event at the same time.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Issue 130: a refused removal toasts that the member left', (
    tester,
  ) async {
    await _pump(
      tester,
      status: EnrollmentStatus.assigned,
      code: SdkErrorCode.invalidState,
    );
    _button(tester, 'Remove').onPressed!();
    await tester.pumpAndSettle();
    // Confirm the removal dialog.
    final confirm = find.byWidgetPredicate(
      (w) =>
          w is ShadButton &&
          w.variant == ShadButtonVariant.destructive &&
          w.child is Text &&
          (w.child! as Text).data == 'Remove',
    );
    tester.widget<ShadButton>(confirm).onPressed!();
    await tester.pumpAndSettle();
    expect(
      find.text('This member has already left the event.'),
      findsOneWidget,
    );
  });
}
