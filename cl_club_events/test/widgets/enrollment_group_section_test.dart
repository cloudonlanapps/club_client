import 'package:cl_club_events/src/models/enrollment_category.dart';
import 'package:cl_club_events/src/models/withdrawal_reasons.dart';
import 'package:cl_club_events/src/widgets/enrollment_group_section.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/credit_scope.dart';

Widget _inactive() => creditScope(
  child: SingleChildScrollView(
    child: EnrollmentGroupSection(
      category: EnrollmentCategory.inactive,
      eventId: programmeId,
      displayNameResolver: (u) => 'Name $u',
      canManage: true,
      enrollments: const {
        'ended': EnrollmentStatus.removed,
        'removed_by_admin': EnrollmentStatus.removed,
        'left': EnrollmentStatus.withdrawn,
      },
      withdrawalReasons: const {
        'ended': trialCreditExhaustedReason,
        'removed_by_admin': 'no-show',
      },
    ),
  ),
);

void main() {
  group('Issue 98: the Inactive group', () {
    testWidgets('Issue 98: collapsed by default, showing its count', (
      tester,
    ) async {
      await tester.pumpWidget(_inactive());
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
      expect(find.text('Name ended'), findsNothing);

      await tester.tap(find.text('Inactive'));
      await tester.pumpAndSettle();

      expect(find.text('Name ended'), findsOneWidget);
      expect(find.text('Name left'), findsOneWidget);
    });

    testWidgets('Issue 98: an ended trial shows a flag, by reason code only', (
      tester,
    ) async {
      await tester.pumpWidget(_inactive());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inactive'));
      await tester.pumpAndSettle();

      // The filter bar's flag, plus the ended trial's row; the admin's
      // removal keeps the plain removed badge.
      expect(find.byIcon(LucideIcons.flag), findsNWidgets(2));
      expect(find.text('removed'), findsOneWidget);
    });

    testWidgets('Issue 98: filters narrow the group', (tester) async {
      await tester.pumpWidget(_inactive());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Inactive'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Withdrawn'));
      await tester.pumpAndSettle();
      expect(find.text('Name left'), findsOneWidget);
      expect(find.text('Name ended'), findsNothing);

      await tester.tap(find.text('Removed'));
      await tester.pumpAndSettle();
      expect(find.text('Name removed_by_admin'), findsOneWidget);
      expect(find.text('Name ended'), findsNothing);
    });
  });
}
