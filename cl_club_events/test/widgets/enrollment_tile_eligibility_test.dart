import 'package:cl_club_events/src/models/enrollment_category.dart';
import 'package:cl_club_events/src/widgets/enrollment_group_section.dart';
import 'package:cl_club_events/src/widgets/enrollment_tile.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show AgeEligibilityText;

import '../support/credit_scope.dart';

Widget _tile({required bool eligible}) => creditScope(
  creditSystem: false,
  child: EnrollmentTile(
    username: 'programme_member',
    status: EnrollmentStatus.assigned,
    eventId: programmeId,
    displayName: 'Programme Member',
    canManage: false,
    eligible: eligible,
  ),
);

void main() {
  group('Issue 42: the enrolment row', () {
    testWidgets('Issue 42: eligible false shows the mark as plain text', (
      tester,
    ) async {
      await tester.pumpWidget(_tile(eligible: false));
      await tester.pumpAndSettle();

      expect(find.text(AgeEligibilityText.noLongerEligible), findsOneWidget);
      expect(find.text('Programme Member'), findsOneWidget);
      expect(find.text('programme_member'), findsOneWidget);
    });

    testWidgets('Issue 42: eligible true shows no mark', (tester) async {
      await tester.pumpWidget(_tile(eligible: true));
      await tester.pumpAndSettle();

      expect(find.text(AgeEligibilityText.noLongerEligible), findsNothing);
      expect(find.text('Programme Member'), findsOneWidget);
    });

    testWidgets('Issue 42: a group marks only the usernames it is given', (
      tester,
    ) async {
      await tester.pumpWidget(
        creditScope(
          creditSystem: false,
          child: SingleChildScrollView(
            child: EnrollmentGroupSection(
              category: EnrollmentCategory.active,
              eventId: programmeId,
              displayNameResolver: (u) => 'Name $u',
              canManage: false,
              enrollments: const {
                'outgrown': EnrollmentStatus.accepted,
                'matching': EnrollmentStatus.assignedTrial,
              },
              ineligibleUsernames: const {'outgrown'},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tiles = tester.widgetList<EnrollmentTile>(
        find.byType(EnrollmentTile),
      );
      expect(
        {for (final t in tiles) t.username: t.eligible},
        {'outgrown': false, 'matching': true},
      );
      expect(find.text(AgeEligibilityText.noLongerEligible), findsOneWidget);
    });
  });
}
