import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_zone/cl_member_zone.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart' hide Visibility;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk show Visibility;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _eventId = 252;

UserPrivate _user({bool admin = false, bool coach = false}) => UserPrivate(
  username: 'viewer',
  displayName: 'Viewer',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: UserRoles(isAdmin: admin, isCoach: coach),
  createdAtUtc: DateTime.utc(2024),
);

Event _event({bool archived = false}) => Event(
  id: _eventId,
  title: 'Broadcast Camp',
  description: '',
  type: EventType.camp,
  visibility: sdk.Visibility.public,
  venueId: 1,
  startTimeUtc: DateTime.utc(2030, 6, 15, 6),
  endTimeUtc: DateTime.utc(2030, 6, 15, 8),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
  deletedAtUtc: archived ? DateTime.utc(2026, 2) : null,
);

class _Auth extends AuthNotifier {
  _Auth(this.user);
  final UserPrivate user;
  @override
  Future<UserPrivate?> build() async => user;
}

class _Events extends ClEventsMasterNotifier {
  _Events(this.event);
  final Event event;
  @override
  Future<Map<int, Event>> build() async => {_eventId: event};
}

final Finder _broadcastButton = find.byTooltip('Broadcast');

/// Mounts the event page for [viewer]; returns how often the Broadcast
/// button opened the screen. Only the title row is under test, so the
/// body's own data is left unloaded.
Future<List<int>> _pump(
  WidgetTester tester,
  UserPrivate viewer, {
  bool archived = false,
}) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final opened = <int>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => _Auth(viewer)),
        clEventsMasterProvider.overrideWith(
          () => _Events(_event(archived: archived)),
        ),
      ],
      child: ShadApp(
        home: Scaffold(
          body: EventDetailsScreen(
            eventId: _eventId,
            onNavigateToEvent: (_) {},
            onHome: () {},
            onDismissed: () {},
            onBroadcast: () => opened.add(1),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  await tester.pump();
  return opened;
}

void main() {
  group("Issue 252: the event page's Broadcast button", () {
    testWidgets('Issue 252: an admin sees it on an active event and it opens '
        'the Broadcast screen', (tester) async {
      final opened = await _pump(tester, _user(admin: true));

      expect(_broadcastButton, findsOneWidget);
      await tester.tap(_broadcastButton);
      await tester.pump();
      expect(opened, hasLength(1));
    });

    testWidgets('Issue 252: a coach who is not an admin does not see it', (
      tester,
    ) async {
      await _pump(tester, _user(coach: true));

      expect(find.text('Broadcast Camp'), findsWidgets);
      expect(_broadcastButton, findsNothing);
    });

    testWidgets('Issue 252: not on an archived event', (tester) async {
      await _pump(tester, _user(admin: true), archived: true);

      expect(find.text('Broadcast Camp'), findsWidgets);
      expect(_broadcastButton, findsNothing);
    });
  });
}
