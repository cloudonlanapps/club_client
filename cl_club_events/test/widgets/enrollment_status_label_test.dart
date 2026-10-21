import 'package:cl_club_events/src/widgets/enrollment_tile.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/credit_scope.dart';

void main() {
  group('Issue 220: the enrolment tile names the status in words', () {
    testWidgets('Issue 220: a pending withdrawal reads as words, not the '
        'enum name', (tester) async {
      await tester.pumpWidget(
        creditScope(
          creditSystem: false,
          child: const EnrollmentTile(
            username: 'leaving_member',
            status: EnrollmentStatus.withdrawRequested,
            eventId: programmeId,
            displayName: 'Leaving Member',
            canManage: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Withdrawal pending'), findsOneWidget);
      expect(find.text('withdrawRequested'), findsNothing);
    });

    testWidgets('Issue 220: no status shows its enum name', (tester) async {
      for (final status in EnrollmentStatus.values) {
        await tester.pumpWidget(
          creditScope(
            creditSystem: false,
            child: EnrollmentStatusBadge(status: status),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(status.name), findsNothing, reason: '$status');
      }
    });
  });
}
