import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_zone/cl_member_zone.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart' hide Visibility;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk show Visibility;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _username = 'issue365_member';
const _eventId = 365;
const _venueId = 9001;

UserPrivate _member() => UserPrivate(
  username: _username,
  displayName: 'Issue 365 Member',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(),
  createdAtUtc: DateTime.now().toUtc(),
);

Event _event() {
  final now = DateTime.now().toUtc();
  return Event(
    id: _eventId,
    title: 'Issue 365 Event',
    description: '',
    type: EventType.camp,
    visibility: sdk.Visibility.public,
    venueId: _venueId,
    startTimeUtc: now.add(const Duration(hours: 1)),
    endTimeUtc: now.add(const Duration(hours: 2)),
    createdAtUtc: now,
    updatedAtUtc: now,
  );
}

class _StaticAuthNotifier extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => _member();
}

class _ThrowingEventsMasterNotifier extends ClEventsMasterNotifier {
  @override
  Future<Map<int, Event>> build() async {
    throw const ServerException(
      statusCode: 403,
      code: 'INSUFFICIENT_PERMISSION',
      message: "Requires one of roles: ['admin', 'coach']",
    );
  }
}

void main() {
  testWidgets(
    'Issue 365: MyEventDetailsScreen renders event for a regular member '
    'even when the admin camp-master endpoint returns 403',
    (tester) async {
      final event = _event();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(_StaticAuthNotifier.new),
            clMyEventDetailProvider(
              (username: _username, eventId: _eventId),
            ).overrideWith((ref) async => event),
            clMyEnrollmentProvider(
              (username: _username, eventId: _eventId),
            ).overrideWith((ref) async => null),
            clEventsMasterProvider.overrideWith(
              _ThrowingEventsMasterNotifier.new,
            ),
          ],
          child: ShadApp(
            home: Scaffold(
              body: MyEventDetailsScreen(
                targetUsername: _username,
                eventId: _eventId,
                onHome: () {},
                onDismissed: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Could not load event'),
        findsNothing,
        reason: 'member access path must not hit the admin-only camp master',
      );
      expect(
        find.text('Issue 365 Event'),
        findsOneWidget,
        reason: 'event title from clMyEventDetailProvider must render',
      );
    },
  );
}
