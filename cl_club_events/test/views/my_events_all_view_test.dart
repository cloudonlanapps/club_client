import 'package:cl_club_events/cl_club_events.dart';
import 'package:cl_club_events/src/models/my_events_list_filter.dart';
import 'package:cl_club_events/src/providers/my_events_list.dart';
import 'package:cl_club_events/src/widgets/cards/event_card.dart';
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart' hide Visibility;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk show Visibility;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _username = 'workflow255_user';
const _eventId = 4242;

UserPrivate _user() => UserPrivate(
  username: _username,
  displayName: 'Test User',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(),
  createdAtUtc: DateTime.now().toUtc(),
);

Event _event() {
  final now = DateTime.now().toUtc();
  return Event(
    id: _eventId,
    title: 'Issue 255 Event',
    description: '',
    type: EventType.oneOff,
    visibility: sdk.Visibility.public,
    venueId: 1,
    startTimeUtc: now.add(const Duration(hours: 1)),
    endTimeUtc: now.add(const Duration(hours: 2)),
    createdAtUtc: now,
    updatedAtUtc: now,
  );
}

class _StaticListNotifier extends MyEventsListNotifier {
  @override
  Future<List<AggregatedMyEvent>> build(MyEventsListFilter arg) async => [
    AggregatedMyEvent(event: _event(), enrollments: const []),
  ];
}

class _StaticAuthNotifier extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => _user();
}

void main() {
  testWidgets(
    'Issue 255: tapping event card on my-events page invokes onEventTap',
    (tester) async {
      int? tappedId;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myEventsListProvider.overrideWith(_StaticListNotifier.new),
            authStateProvider.overrideWith(_StaticAuthNotifier.new),
            // EventCard now resolves a list cover via eventCoverImageProvider;
            // stub it so the card doesn't reach secureClientProvider (#713).
            eventCoverImageProvider.overrideWith((ref, id) async => null),
            imageAuthHeadersProvider.overrideWith((ref) async => const {}),
          ],
          child: ShadApp(
            home: Scaffold(
              body: MyEventsAllView(
                currentUser: _user(),
                targetUsername: _username,
                onEventTap: (id) => tappedId = id,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      final cardFinder = find.byType(EventCard);
      expect(
        cardFinder,
        findsOneWidget,
        reason: 'one EventCard should render for the single mock event',
      );

      final card = tester.widget<EventCard>(cardFinder);
      expect(
        card.onTap,
        isNotNull,
        reason: 'MyEventsAllView must forward onEventTap as the card onTap',
      );

      card.onTap!();
      expect(
        tappedId,
        equals(_eventId),
        reason: 'onEventTap callback must receive the tapped event id',
      );
    },
  );

  testWidgets(
    'Issue 255: omitting onEventTap leaves event card non-tappable',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myEventsListProvider.overrideWith(_StaticListNotifier.new),
            authStateProvider.overrideWith(_StaticAuthNotifier.new),
            // EventCard now resolves a list cover via eventCoverImageProvider;
            // stub it so the card doesn't reach secureClientProvider (#713).
            eventCoverImageProvider.overrideWith((ref, id) async => null),
            imageAuthHeadersProvider.overrideWith((ref) async => const {}),
          ],
          child: ShadApp(
            home: Scaffold(
              body: MyEventsAllView(
                currentUser: _user(),
                targetUsername: _username,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      final card = tester.widget<EventCard>(find.byType(EventCard));
      expect(
        card.onTap,
        isNull,
        reason: 'when no onEventTap is provided the card stays non-tappable',
      );
    },
  );
}
