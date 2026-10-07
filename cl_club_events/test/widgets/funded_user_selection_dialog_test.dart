import 'package:cl_club_events/src/widgets/funded_user_selection_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/src/widgets/user_selection_tile.dart'
    show UserSelectionTile;
import 'package:ui_lib/ui_lib.dart' show PickerUser;

import '../support/credit_scope.dart';

const _users = [
  PickerUser(username: 'funded', displayName: 'Funded'),
  PickerUser(username: 'broke', displayName: 'Broke'),
];

void main() {
  group('Issue 105: the Assign picker on a programme', () {
    testWidgets('Issue 105: an unfunded member is blocked, with add credit', (
      tester,
    ) async {
      await tester.pumpWidget(
        creditScope(
          user: person('an_admin', admin: true),
          accounts: {
            'funded': [account('funded', 3)],
          },
          child: const FundedUserSelectionDialog(
            title: 'Assign Users',
            users: _users,
            eventId: programmeId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tiles = tester
          .widgetList<UserSelectionTile>(find.byType(UserSelectionTile))
          .toList();
      expect(tiles.firstWhere((t) => t.user.username == 'broke').onTap, isNull);
      expect(
        tiles.firstWhere((t) => t.user.username == 'funded').onTap,
        isNotNull,
      );
      expect(find.bySemanticsLabel('Add credit'), findsOneWidget);
    });

    testWidgets('Issue 105: a camp blocks nobody', (tester) async {
      await tester.pumpWidget(
        creditScope(
          child: const FundedUserSelectionDialog(
            title: 'Assign Users',
            users: _users,
            eventId: campId,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Add credit'), findsNothing);
    });
  });
}
