import 'package:cl_club_events/src/widgets/conflict_breakdown_dialog.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  Widget wrap(Widget child) => ShadApp(
    home: Scaffold(body: child),
  );

  UserConflictReport sampleReport({
    String username = 'alice',
  }) {
    return UserConflictReport.fromMap({
      'userConflicts': [
        {
          'username': username,
          'events': const [
            {
              'eventId': 1,
              'eventTitle': 'Other Programme',
              'eventType': 'programme',
              'occurrences': [
                {
                  'targetStartUtc': 1700000000000,
                  'targetEndUtc': 1700003600000,
                  'otherStartUtc': 1700001800000,
                  'otherEndUtc': 1700005400000,
                },
              ],
            },
          ],
        },
      ],
    });
  }

  testWidgets('renders the conflicting user, event and occurrence pair', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ConflictBreakdownDialog(
          report: sampleReport(),
          title: 'Conflicts',
        ),
      ),
    );

    expect(find.text('Conflicts'), findsOneWidget);
    expect(find.textContaining('alice'), findsOneWidget);
    expect(find.textContaining('Other Programme'), findsOneWidget);
    expect(find.textContaining('overlaps'), findsOneWidget);
  });

  testWidgets('uses the display-name resolver when one is supplied', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ConflictBreakdownDialog(
          report: sampleReport(),
          title: 'Conflicts',
          displayNameResolver: (u) => u == 'alice' ? 'Alice Anderson' : null,
        ),
      ),
    );

    expect(find.textContaining('Alice Anderson (alice)'), findsOneWidget);
  });

  testWidgets('summary mentions the right number of users', (tester) async {
    final report = UserConflictReport.fromMap(const {
      'userConflicts': [
        {'username': 'a', 'events': <Map<String, dynamic>>[]},
        {'username': 'b', 'events': <Map<String, dynamic>>[]},
      ],
    });
    await tester.pumpWidget(
      wrap(ConflictBreakdownDialog(report: report, title: 'Conflicts')),
    );
    expect(
      find.textContaining('2 selected users already have overlapping'),
      findsOneWidget,
    );
  });
}
