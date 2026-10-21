import 'package:cl_club_members/src/views/my_group_details_view.dart'
    show PendingJoinRequestCard;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  testWidgets('Issue 195: the pending request card shows the request date '
      'from its millisecond timestamp', (tester) async {
    // Local noon, so the date is the same in every time zone the test runs.
    final requestedAt = DateTime(2026, 10, 1, 12).millisecondsSinceEpoch;
    await tester.pumpWidget(
      ProviderScope(
        child: ShadApp(
          home: Scaffold(
            body: PendingJoinRequestCard(
              username: 'member_a',
              request: JoinRequest(
                id: 1,
                groupId: 2,
                groupName: 'Juniors',
                username: 'member_a',
                status: JoinRequestStatus.pending,
                requestedAt: requestedAt,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('on Oct 1, 2026.'), findsOneWidget);
  });
}
