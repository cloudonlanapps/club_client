import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_zone/cl_member_zone.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart' hide Visibility;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk show Visibility;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _eventId = 36;

UserPrivate _superAdmin() => UserPrivate(
  username: 'root',
  displayName: 'root',
  status: UserStatus.active,
  isSuperAdmin: true,
  roles: const UserRoles(),
  createdAtUtc: DateTime.utc(2024),
);

Event _archivedEvent() => Event(
  id: _eventId,
  title: 'workflow_archive_camp',
  description: '',
  type: EventType.camp,
  visibility: sdk.Visibility.public,
  venueId: 1,
  startTimeUtc: DateTime.utc(2030, 6, 15, 6),
  endTimeUtc: DateTime.utc(2030, 6, 15, 8),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
  deletedAtUtc: DateTime.utc(2026, 2),
);

class _Auth extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => _superAdmin();
}

class _Events extends ClEventsMasterNotifier {
  @override
  Future<Map<int, Event>> build() async => {_eventId: _archivedEvent()};

  @override
  Future<void> hardDeleteEvent(int eventId) async => removeLocally(eventId);
}

void main() {
  testWidgets(
    'Issue 36: EventDetailsScreen leaves through onDeleted once the event '
    'is deleted from Event Management',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var deleted = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(_Auth.new),
            clEventsMasterProvider.overrideWith(_Events.new),
          ],
          child: ShadApp(
            home: Scaffold(
              body: EventDetailsScreen(
                eventId: _eventId,
                onNavigateToEvent: (_) {},
                onHome: () {},
                onDismissed: () {},
                onDeleted: () => deleted++,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      await tester.tap(find.widgetWithText(ShadButton, 'Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ShadButton, 'Delete').last);
      await tester.pumpAndSettle();

      expect(deleted, 1);
    },
  );
}
