import 'package:cl_club_events/src/models/event_display_status.dart';
import 'package:cl_club_events/src/providers/event_display_status.dart';
import 'package:cl_club_events/src/views/event_list_view.dart';
import 'package:cl_club_events/src/widgets/cards/event_card.dart';
import 'package:cl_club_events/src/widgets/event_filter_popover.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show eventCoverImageProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/credit_scope.dart';

const _liveId = 21;
const _archivedId = 22;

Future<void> _pump(WidgetTester tester, UserPrivate user) async {
  await tester.pumpWidget(
    creditScope(
      user: user,
      creditSystem: false,
      events: {
        _liveId: event(_liveId, EventType.camp),
        _archivedId: event(_archivedId, EventType.camp).copyWith(
          deletedAtUtc: () => DateTime.utc(2026, 2),
        ),
      },
      extra: [
        eventCoverImageProvider.overrideWith((ref, id) async => null),
        imageAuthHeadersProvider.overrideWith((ref) async => const {}),
        eventDisplayStatusProvider.overrideWith(
          (ref, id) async => EventDisplayStatus.comingSoon,
        ),
      ],
      child: EventListView(
        eventType: EventType.camp,
        onEventTap: (_) {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openFilter(WidgetTester tester) async {
  await tester.tap(find.text('Filter'));
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 36: Show archived on the staff event lists', () {
    testWidgets('Issue 36: an admin turns it on and sees the archived event', (
      tester,
    ) async {
      await _pump(tester, person('an_admin', admin: true));
      expect(find.byType(EventCard), findsOneWidget);
      expect(find.text(EventCard.archivedCaption), findsNothing);

      await _openFilter(tester);
      expect(find.text(EventFilterPopover.showArchivedLabel), findsOneWidget);
      await tester.tap(find.byType(ShadSwitch).last);
      await tester.pumpAndSettle();

      expect(find.byType(EventCard), findsNWidgets(2));
      expect(find.text(EventCard.archivedCaption), findsOneWidget);
    });

    testWidgets('Issue 36: a coach is not offered Show archived', (
      tester,
    ) async {
      await _pump(tester, person('a_coach', coach: true));

      await _openFilter(tester);

      expect(find.text('Include past'), findsOneWidget);
      expect(find.text(EventFilterPopover.showArchivedLabel), findsNothing);
      expect(find.byType(EventCard), findsOneWidget);
    });
  });
}
