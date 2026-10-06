import 'package:cl_club_events/src/models/event_display_status.dart';
import 'package:cl_club_events/src/providers/event_display_status.dart';
import 'package:cl_club_events/src/widgets/cards/event_card.dart';
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EntityImage;

const _username = 'demo_user';
const _eventId = 501;

Event _event({
  required EventType type,
  String title = 'Test Event',
}) {
  final now = DateTime.now().toUtc();
  return Event(
    id: _eventId,
    title: title,
    description: '',
    type: type,
    visibility: Visibility.private,
    venueId: 1,
    startTimeUtc: now,
    endTimeUtc: now.add(const Duration(hours: 1)),
    createdAtUtc: now,
    updatedAtUtc: now,
  );
}

class _StaticCampNotifier extends ClEventsMasterNotifier {
  _StaticCampNotifier(this._events);
  final Map<int, Event> _events;
  @override
  Future<Map<int, Event>> build() async => _events;
}

class _StaticMyEventsNotifier extends ClMyEventsMasterNotifier {
  _StaticMyEventsNotifier(this._events);
  final List<Event> _events;
  @override
  Future<List<Event>> build(String arg) async => _events;
}

class _NoAuthNotifier extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => null;
}

class _StaticAuthNotifier extends AuthNotifier {
  _StaticAuthNotifier(this._user);
  final UserPrivate _user;
  @override
  Future<UserPrivate?> build() async => _user;
}

UserPrivate _adminUser() => UserPrivate(
  username: 'admin_user',
  displayName: 'Admin User',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(isAdmin: true),
  createdAtUtc: DateTime.now().toUtc(),
);

Future<void> _pumpCard(
  WidgetTester tester, {
  required Event event,
  String? username,
  EventDisplayStatus? status,
  Enrollment? enrollment,
  UserPrivate? actingUser,
  VoidCallback? onEnrollments,
  String? coverUrl,
  double width = 800,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clEventsMasterProvider.overrideWith(
          () => _StaticCampNotifier({event.id: event}),
        ),
        eventCoverImageProvider(event.id).overrideWith((ref) async => coverUrl),
        imageAuthHeadersProvider.overrideWith((ref) async => const {}),
        if (username != null)
          clMyEventsMasterProvider.overrideWith(
            () => _StaticMyEventsNotifier([event]),
          ),
        authStateProvider.overrideWith(
          actingUser == null
              ? _NoAuthNotifier.new
              : () => _StaticAuthNotifier(actingUser),
        ),
        eventDisplayStatusProvider(event.id).overrideWith(
          (ref) async => status ?? EventDisplayStatus.ongoing,
        ),
        if (username != null)
          clMyEnrollmentProvider(
            (username: username, eventId: event.id),
          ).overrideWith((ref) async => enrollment),
      ],
      child: ShadApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            child: EventCard(
              eventId: event.id,
              username: username,
              onEnrollments: onEnrollments,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  await tester.pump();
}

void main() {
  group('Issue 36: EventCard of an archived event', () {
    testWidgets('Issue 36: an archived event reads Archived, not its status', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        event: _event(type: EventType.camp).copyWith(
          deletedAtUtc: () => DateTime.utc(2026, 3),
        ),
        status: EventDisplayStatus.ongoing,
      );
      expect(find.text('Archived'), findsOneWidget);
      expect(find.text('Ongoing'), findsNothing);
    });

    testWidgets('Issue 36: an archived event offers no Enrollments action', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        event: _event(type: EventType.camp).copyWith(
          deletedAtUtc: () => DateTime.utc(2026, 3),
        ),
        actingUser: _adminUser(),
        onEnrollments: () {},
      );
      expect(find.text('Enrollments'), findsNothing);
    });

    testWidgets('Issue 36: a live event is not marked Archived', (
      tester,
    ) async {
      await _pumpCard(tester, event: _event(type: EventType.camp));
      expect(find.text('Archived'), findsNothing);
    });
  });

  group('Issue 295: EventCard temporal status caption', () {
    testWidgets('Issue 295: admin lens — ongoing shows Ongoing', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        event: _event(type: EventType.camp),
        status: EventDisplayStatus.ongoing,
      );
      expect(find.text('Ongoing'), findsOneWidget);
      expect(find.text('Camp'), findsNothing);
    });

    testWidgets('Issue 295: admin lens — coming-soon shows Coming Soon', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        event: _event(type: EventType.camp),
        status: EventDisplayStatus.comingSoon,
      );
      expect(find.text('Coming Soon'), findsOneWidget);
    });

    testWidgets('Issue 295: admin lens — ended shows Ended', (tester) async {
      await _pumpCard(
        tester,
        event: _event(type: EventType.camp),
        status: EventDisplayStatus.ended,
      );
      expect(find.text('Ended'), findsOneWidget);
    });

    testWidgets('Issue 295: admin lens — cancelled shows Cancelled', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        event: _event(type: EventType.camp),
        status: EventDisplayStatus.cancelled,
      );
      expect(find.text('Cancelled'), findsOneWidget);
    });

    testWidgets(
      'Issue 295: member lens — enrollment suffix wins over temporal',
      (tester) async {
        final now = DateTime.now().toUtc();
        await _pumpCard(
          tester,
          event: _event(type: EventType.camp),
          username: _username,
          status: EventDisplayStatus.ended,
          enrollment: Enrollment(
            id: 1,
            membername: _username,
            eventId: _eventId,
            status: EnrollmentStatus.accepted,
            createdAtUtc: now,
          ),
        );
        expect(find.text('You are accepted'), findsOneWidget);
        expect(find.text('Ended'), findsNothing);
      },
    );

    testWidgets(
      'Issue 295: member lens — temporal label fills in when no enrollment',
      (tester) async {
        await _pumpCard(
          tester,
          event: _event(type: EventType.camp),
          username: _username,
          status: EventDisplayStatus.cancelled,
        );
        expect(find.text('Cancelled'), findsOneWidget);
      },
    );

    testWidgets(
      'Issue 295: member lens — terminal enrollment falls back to temporal',
      (tester) async {
        final now = DateTime.now().toUtc();
        await _pumpCard(
          tester,
          event: _event(type: EventType.camp),
          username: _username,
          status: EventDisplayStatus.ended,
          enrollment: Enrollment(
            id: 2,
            membername: _username,
            eventId: _eventId,
            status: EnrollmentStatus.withdrawn,
            createdAtUtc: now,
          ),
        );
        expect(find.text('Ended'), findsOneWidget);
      },
    );
  });

  group('Issue 501: EventCard routes actions through trailingActions', () {
    testWidgets(
      'Issue 501: admin lens surfaces Enrollments via the typed action '
      'slot and fires onPressed at mobile width',
      (tester) async {
        var tapped = false;
        await _pumpCard(
          tester,
          event: _event(type: EventType.camp),
          actingUser: _adminUser(),
          onEnrollments: () => tapped = true,
          width: 360,
        );

        // The resolver now hosts the actions and hands them to EventCard via
        // EntityCard.trailingActions — the primary action renders inline even
        // on a narrow (mobile) surface.
        expect(find.text('Enrollments'), findsOneWidget);

        await tester.tap(find.text('Enrollments'));
        await tester.pump();
        expect(tapped, isTrue);
      },
    );

    testWidgets(
      'Issue 501: admin lens with no onEnrollments renders no action',
      (tester) async {
        await _pumpCard(
          tester,
          event: _event(type: EventType.camp),
          actingUser: _adminUser(),
          width: 360,
        );
        expect(find.text('Enrollments'), findsNothing);
      },
    );
  });

  group('Issue 713: EventCard shows the cover image in the list', () {
    testWidgets(
      'Issue 713: renders the event cover when one is available',
      (tester) async {
        await _pumpCard(
          tester,
          event: _event(type: EventType.camp),
          actingUser: _adminUser(),
          coverUrl: 'https://example.test/cover-501.png',
        );
        final image = tester.widget<EntityImage>(find.byType(EntityImage));
        expect(image.imageUrl, 'https://example.test/cover-501.png');
      },
    );

    testWidgets(
      'Issue 713: falls back to the placeholder when there is no cover',
      (tester) async {
        await _pumpCard(
          tester,
          event: _event(type: EventType.camp),
          actingUser: _adminUser(),
        );
        final image = tester.widget<EntityImage>(find.byType(EntityImage));
        expect(image.imageUrl, isNull);
      },
    );
  });
}
