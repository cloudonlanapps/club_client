import 'package:cl_club_events/src/widgets/enrollment_tile.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/credit_scope.dart';

/// The row's width on a Galaxy A13, where the overflow was seen.
const double _phoneRowWidth = 326;

const String _member = 'workflow_credit_member_with_a_long_name';

void main() {
  group('Issue 296: the enrollment row at a phone width', () {
    for (final (status, eligible) in [
      for (final status in EnrollmentStatus.values) ...[
        (status, true),
        (status, false),
      ],
    ]) {
      testWidgets('Issue 296: an admin sees ${status.name}'
          '${eligible ? '' : ', no longer eligible,'} without an '
          'overflow', (tester) async {
        tester.view
          ..physicalSize = const Size(360, 800)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          creditScope(
            user: person('the_admin', admin: true),
            // No credit: every action credit forbids shows its reason.
            roster: {_member: rosterRow(_member)},
            child: Center(
              child: SizedBox(
                width: _phoneRowWidth,
                child: EnrollmentTile(
                  username: _member,
                  status: status,
                  eventId: programmeId,
                  displayName: 'Workflow Credit Member With A Long Name',
                  canManage: true,
                  withdrawalReason: status == EnrollmentStatus.removed
                      ? 'trialCreditExhausted'
                      : null,
                  eligible: eligible,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  });
}
