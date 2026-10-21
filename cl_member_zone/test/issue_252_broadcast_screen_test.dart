import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_zone/cl_member_zone.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart' hide Visibility;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk show Visibility;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

final UserPrivate _admin = UserPrivate(
  username: 'admin1',
  displayName: 'Admin One',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(isAdmin: true),
  createdAtUtc: DateTime.utc(2024),
);

class _StubAuth extends AuthNotifier {
  _StubAuth(this._u);
  final UserPrivate _u;
  @override
  Future<UserPrivate?> build() async => _u;
}

/// One send the screen asked the master for.
typedef _Sent = ({
  BroadcastScope scope,
  AudienceSelector audience,
  String text,
});

/// Lists [listed] and records every send, answering with a broadcast that
/// carries the scope as `payload.source`, as the real master sends it.
class _Broadcasts extends ClBroadcastsMasterNotifier {
  _Broadcasts(this.listed);

  final List<Broadcast> listed;
  final List<_Sent> sent = [];

  @override
  Future<Map<int, Broadcast>> build() async => {
    for (final b in listed) b.id: b,
  };

  @override
  Future<Broadcast> send({
    required BroadcastScope scope,
    required AudienceSelector audience,
    required String text,
    bool email = false,
    String? emailSubject,
  }) async {
    sent.add((scope: scope, audience: audience, text: text));
    final created = _broadcast(
      100 + sent.length,
      audience,
      text: text,
      source: scope,
    );
    state = AsyncData({...state.requireValue, created.id: created});
    return created;
  }
}

class _Users extends ClUsersMasterNotifier {
  @override
  Future<Map<String, UserInfo>> build() async => {
    'alice': const UserInfo(
      username: 'alice',
      displayName: 'Alice Smith',
      status: UserStatus.active,
      isSuperAdmin: false,
      roles: UserRoles(),
    ),
  };
}

class _Groups extends ClGroupsMasterNotifier {
  @override
  Future<Map<int, Group>> build() async => {
    3: Group(
      id: 3,
      name: 'Juniors',
      kind: GroupKind.manual,
      createdAtUtc: DateTime.utc(2025),
    ),
  };
}

class _Events extends ClEventsMasterNotifier {
  @override
  Future<Map<int, Event>> build() async => {
    9: Event(
      id: 9,
      title: 'Summer Camp',
      description: '',
      type: EventType.camp,
      visibility: sdk.Visibility.public,
      venueId: 1,
      startTimeUtc: DateTime.utc(2026),
      endTimeUtc: DateTime.utc(2026, 2),
      createdAtUtc: DateTime.utc(2026),
      updatedAtUtc: DateTime.utc(2026),
    ),
  };
}

/// The staff Staff only sends to, per scope.
const Map<BroadcastScopeKind, List<String>> _staff = {
  BroadcastScopeKind.all: ['admin1', 'coach1', 'coach2'],
  BroadcastScopeKind.group: ['coach1'],
  BroadcastScopeKind.event: ['coach2', 'organizer1'],
};

UserInfo _info(String username, String name) => UserInfo(
  username: username,
  displayName: name,
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(),
);

Broadcast _broadcast(
  int id,
  AudienceSelector audience, {
  String? text,
  BroadcastScope? source,
}) => Broadcast(
  id: id,
  audienceSelector: audience,
  payload: {
    'v': 1,
    'type': 'broadcast.text',
    'data': {'text': text ?? 'message $id'},
    if (source != null) 'source': source.toPayload(),
  },
  sentAtUtc: DateTime.utc(2026, 1, 1, 0, id),
  status: BroadcastStatus.sent,
  recipientCount: 1,
);

Future<_Broadcasts> _pump(
  WidgetTester tester,
  BroadcastScope scope, {
  List<Broadcast> listed = const [],
}) async {
  await tester.binding.setSurfaceSize(const Size(1024, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final broadcasts = _Broadcasts(listed);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => _StubAuth(_admin)),
        clBroadcastsMasterProvider.overrideWith(() => broadcasts),
        clUsersMasterProvider.overrideWith(_Users.new),
        clGroupsMasterProvider.overrideWith(_Groups.new),
        clEventsMasterProvider.overrideWith(_Events.new),
        clBroadcastStaffProvider.overrideWith(
          (ref, scope) async => _staff[scope.kind] ?? [scope.username!],
        ),
        clBroadcastMembersProvider.overrideWith(
          (ref, scope) async => [
            _info('alice', 'Alice Smith'),
            _info('bob', 'Bob Jones'),
            _info('carol', 'Carol King'),
          ],
        ),
      ],
      child: ShadApp(
        home: Scaffold(
          body: BroadcastScreen(scope: scope, onClose: () {}, onHome: () {}),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return broadcasts;
}

Future<void> _send(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(EditableText), text);
  await tester.pump();
  await tester.tap(find.widgetWithText(ShadButton, 'Send'));
  await tester.pumpAndSettle();
}

Future<void> _staffOnly(WidgetTester tester) async {
  tester
      .widget<ShadSwitch>(find.byKey(const ValueKey('broadcast-staff-only')))
      .onChanged
      ?.call(true);
  await tester.pumpAndSettle();
}

const List<BroadcastScope> _narrowable = [
  BroadcastScope.all(),
  BroadcastScope.group(3),
  BroadcastScope.event(9),
];

void main() {
  group('Issue 252: each screen sends to its audience, with its source', () {
    final cases = <BroadcastScope, AudienceSelector>{
      const BroadcastScope.all(): const AudienceSelector.allUsers(),
      const BroadcastScope.group(3): const AudienceSelector.group(3),
      const BroadcastScope.event(9): const AudienceSelector.eventMembers(9),
      const BroadcastScope.member('alice'): AudienceSelector.users(const [
        'alice',
      ]),
    };
    for (final MapEntry(key: scope, value: audience) in cases.entries) {
      testWidgets('Issue 252: $scope sends ${audience.toMap()}', (
        tester,
      ) async {
        final broadcasts = await _pump(tester, scope);

        await _send(tester, 'Ice time moved');

        final sent = broadcasts.sent.single;
        expect(sent.audience, audience);
        expect(sent.scope, scope);
        expect(sent.text, 'Ice time moved');
        // The sent broadcast shows in this screen's list.
        expect(find.text('Ice time moved'), findsOneWidget);
      });
    }

    testWidgets('Issue 252: the title row names the audience', (tester) async {
      await _pump(tester, const BroadcastScope.group(3));
      expect(find.text('To the members of Juniors'), findsOneWidget);
    });

    testWidgets('Issue 252: the one-to-one screen names the member', (
      tester,
    ) async {
      await _pump(tester, const BroadcastScope.member('alice'));
      expect(find.text('To Alice Smith'), findsOneWidget);
    });
  });

  group('Issue 252: Staff only', () {
    for (final scope in _narrowable) {
      testWidgets('Issue 252: Staff only on $scope sends to its staff as '
          'users', (tester) async {
        final broadcasts = await _pump(tester, scope);

        await _staffOnly(tester);
        await _send(tester, 'Staff meeting');

        final sent = broadcasts.sent.single;
        expect(sent.audience, AudienceSelector.users(_staff[scope.kind]!));
        expect(sent.scope, scope);
      });
    }

    testWidgets('Issue 252: Staff only with no staff sends nothing', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1024, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final broadcasts = _Broadcasts(const []);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(() => _StubAuth(_admin)),
            clBroadcastsMasterProvider.overrideWith(() => broadcasts),
            clGroupsMasterProvider.overrideWith(_Groups.new),
            clBroadcastStaffProvider.overrideWith((ref, scope) async => []),
            clBroadcastMembersProvider.overrideWith((ref, scope) async => []),
          ],
          child: ShadApp(
            home: Scaffold(
              body: BroadcastScreen(
                scope: const BroadcastScope.group(3),
                onClose: () {},
                onHome: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _staffOnly(tester);
      await _send(tester, 'Staff meeting');

      expect(broadcasts.sent, isEmpty);
      expect(find.text('There is no staff to send this to.'), findsOneWidget);
    });
  });

  group('Issue 252: Choose members', () {
    for (final scope in _narrowable) {
      testWidgets('Issue 252: Choose members on $scope sends to exactly the '
          'picked members', (tester) async {
        final broadcasts = await _pump(tester, scope);

        await tester.tap(find.widgetWithText(ShadButton, 'Choose members'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Alice Smith'));
        await tester.tap(find.text('Carol King'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ShadButton, 'Choose (2)'));
        await tester.pumpAndSettle();
        expect(find.text('Sends to the 2 chosen members.'), findsOneWidget);

        await _send(tester, 'See you Saturday');

        final sent = broadcasts.sent.single;
        expect(sent.audience, AudienceSelector.users(const ['alice', 'carol']));
        expect(sent.scope, scope);
      });
    }
  });

  testWidgets('Issue 252: the one-to-one screen has no Staff only and no '
      'Choose members', (tester) async {
    await _pump(tester, const BroadcastScope.member('alice'));

    expect(find.byType(ShadSwitch), findsNothing);
    expect(find.text('Staff only'), findsNothing);
    expect(find.text('Choose members'), findsNothing);
  });

  group("Issue 252: each screen's sent list shows only its source", () {
    final listed = [
      _broadcast(1, const AudienceSelector.allUsers(), text: 'legacy all'),
      _broadcast(
        2,
        AudienceSelector.users(const ['coach1']),
        text: 'all staff',
        source: const BroadcastScope.all(),
      ),
      _broadcast(
        3,
        AudienceSelector.users(const ['coach1']),
        text: 'group staff',
        source: const BroadcastScope.group(3),
      ),
      _broadcast(
        4,
        const AudienceSelector.eventMembers(9),
        text: 'event members',
        source: const BroadcastScope.event(9),
      ),
      _broadcast(
        5,
        AudienceSelector.users(const ['alice']),
        text: 'to alice',
        source: const BroadcastScope.member('alice'),
      ),
    ];
    final expected = <BroadcastScope, List<String>>{
      const BroadcastScope.all(): ['legacy all', 'all staff'],
      const BroadcastScope.group(3): ['group staff'],
      const BroadcastScope.event(9): ['event members'],
      const BroadcastScope.member('alice'): ['to alice'],
    };
    const everything = [
      'legacy all',
      'all staff',
      'group staff',
      'event members',
      'to alice',
    ];
    for (final MapEntry(key: scope, value: shown) in expected.entries) {
      testWidgets('Issue 252: $scope lists $shown', (tester) async {
        await _pump(tester, scope, listed: listed);

        for (final text in everything) {
          expect(
            find.text(text),
            shown.contains(text) ? findsOneWidget : findsNothing,
            reason: text,
          );
        }
      });
    }
  });

  testWidgets('Issue 252: the screen has no panel presentation: no See more', (
    tester,
  ) async {
    await _pump(
      tester,
      const BroadcastScope.all(),
      listed: [
        for (var id = 1; id <= 5; id++)
          _broadcast(id, const AudienceSelector.allUsers()),
      ],
    );

    expect(find.text('See more'), findsNothing);
    for (var id = 1; id <= 5; id++) {
      expect(find.text('message $id'), findsOneWidget);
    }
  });

  testWidgets('Issue 252: a non-admin is refused the screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            () => _StubAuth(
              UserPrivate(
                username: 'coach1',
                displayName: 'Coach',
                status: UserStatus.active,
                isSuperAdmin: false,
                roles: const UserRoles(isCoach: true),
                createdAtUtc: DateTime.utc(2024),
              ),
            ),
          ),
        ],
        child: ShadApp(
          home: Scaffold(
            body: BroadcastScreen(
              scope: const BroadcastScope.all(),
              onClose: () {},
              onHome: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Access Denied'), findsOneWidget);
  });
}
