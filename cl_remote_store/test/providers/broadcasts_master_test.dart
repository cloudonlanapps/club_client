import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

/// Records every `createBroadcast` call so tests can assert what the provider
/// forwarded.
class _FakeBroadcasts extends Fake implements BroadcastSource {
  final List<Map<String, dynamic>> calls = [];

  Broadcast _stub(AudienceSelector audienceSelector) => Broadcast(
    id: calls.length,
    audienceSelector: audienceSelector,
    payload: const {},
    sentAtUtc: DateTime.utc(2026),
    status: BroadcastStatus.sent,
    recipientCount: 1,
  );

  @override
  Future<PaginatedList<Broadcast>> listBroadcasts({
    int offset = 0,
    int limit = 20,
  }) async => const PaginatedList<Broadcast>(
    items: [],
    total: 0,
    offset: 0,
    limit: 20,
  );

  @override
  Future<Broadcast> createBroadcast({
    required AudienceSelector audienceSelector,
    required Map<String, dynamic> payload,
    DateTime? expiresAtUtc,
    bool email = false,
    String? emailSubject,
    String? emailBody,
  }) async {
    calls.add({
      'audienceSelector': audienceSelector,
      'payload': payload,
      'email': email,
      'emailSubject': emailSubject,
      'emailBody': emailBody,
    });
    return _stub(audienceSelector);
  }
}

SecureClient _buildClient(BroadcastSource broadcasts) => fakeSecureClient(
  broadcasts: broadcasts,
);

UserInfo _admin() => const UserInfo(
  username: 'admin',
  displayName: 'admin',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: UserRoles(isAdmin: true),
);

ProviderContainer _container(BroadcastSource broadcasts, {UserInfo? user}) {
  final c = ProviderContainer(
    overrides: [
      secureClientProvider.overrideWith(
        (ref) async => _buildClient(broadcasts),
      ),
      currentUserProvider.overrideWith((ref) => user ?? _admin()),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('ClBroadcastsMasterNotifier', () {
    test('Issue 737: send without email omits the email fields', () async {
      final fake = _FakeBroadcasts();
      final c = _container(fake);
      await c.read(clBroadcastsMasterProvider.future);

      await c
          .read(clBroadcastsMasterProvider.notifier)
          .send(
            scope: const BroadcastScope.all(),
            audience: const AudienceSelector.allUsers(),
            text: 'hello',
          );

      final call = fake.calls.single;
      expect(call['email'], isFalse);
      expect(call['emailSubject'], isNull);
      expect(call['emailBody'], isNull);
      expect(
        (call['audienceSelector'] as AudienceSelector).kind,
        AudienceKind.allUsers,
      );
    });

    test('Issue 737: send with email forwards subject and body=text', () async {
      final fake = _FakeBroadcasts();
      final c = _container(fake);
      await c.read(clBroadcastsMasterProvider.future);

      await c
          .read(clBroadcastsMasterProvider.notifier)
          .send(
            scope: const BroadcastScope.group(42),
            audience: const AudienceSelector.group(42),
            text: 'practice moved',
            email: true,
            emailSubject: 'Message for U12',
          );

      final call = fake.calls.single;
      expect(call['email'], isTrue);
      expect(call['emailSubject'], 'Message for U12');
      expect(call['emailBody'], 'practice moved');
    });

    test('Issue 252: send posts the audience as given and the screen as '
        'payload.source', () async {
      final fake = _FakeBroadcasts();
      final c = _container(fake);
      await c.read(clBroadcastsMasterProvider.future);
      final narrowed = AudienceSelector.users(const ['coach1', 'admin1']);

      await c
          .read(clBroadcastsMasterProvider.notifier)
          .send(
            scope: const BroadcastScope.event(7),
            audience: narrowed,
            text: 'bring skates',
          );

      final call = fake.calls.single;
      expect(call['audienceSelector'], narrowed);
      expect(call['payload'], {
        'v': 1,
        'type': 'broadcast.text',
        'data': {'text': 'bring skates'},
        'source': {'kind': 'event', 'id': 7},
      });
    });
  });

  group('Issue 252: BroadcastScope', () {
    test('Issue 252: each scope sends to its whole audience', () {
      expect(
        const BroadcastScope.all().audience,
        const AudienceSelector.allUsers(),
      );
      expect(
        const BroadcastScope.group(3).audience,
        const AudienceSelector.group(3),
      );
      expect(
        const BroadcastScope.event(9).audience,
        const AudienceSelector.eventMembers(9),
      );
      expect(
        const BroadcastScope.member('alice').audience,
        AudienceSelector.users(const ['alice']),
      );
    });

    test('Issue 252: the source round-trips through the payload', () {
      const scopes = [
        BroadcastScope.all(),
        BroadcastScope.group(3),
        BroadcastScope.event(9),
        BroadcastScope.member('alice'),
      ];
      for (final scope in scopes) {
        expect(
          BroadcastScope.fromPayload({'source': scope.toPayload()}),
          scope,
        );
      }
      expect(const BroadcastScope.member('alice').toPayload(), {
        'kind': 'member',
        'id': 'alice',
      });
      expect(BroadcastScope.fromPayload(const {}), isNull);
    });

    test('Issue 252: only the one-to-one scope cannot be narrowed', () {
      expect(const BroadcastScope.all().canNarrow, isTrue);
      expect(const BroadcastScope.group(3).canNarrow, isTrue);
      expect(const BroadcastScope.event(9).canNarrow, isTrue);
      expect(const BroadcastScope.member('alice').canNarrow, isFalse);
    });
  });

  test("Issue 252: each screen's sent list shows only its source, and the "
      'all-members list keeps all_users broadcasts sent without one', () async {
    final fake = _ListedBroadcasts([
      _broadcast(1, const AudienceSelector.allUsers()),
      _broadcast(2, const AudienceSelector.group(3)),
      _broadcast(
        3,
        AudienceSelector.users(const ['coach1']),
        source: const BroadcastScope.group(3),
      ),
      _broadcast(
        4,
        AudienceSelector.users(const ['coach1']),
        source: const BroadcastScope.all(),
      ),
      _broadcast(
        5,
        const AudienceSelector.eventMembers(9),
        source: const BroadcastScope.event(9),
      ),
      _broadcast(
        6,
        AudienceSelector.users(const ['alice']),
        source: const BroadcastScope.member('alice'),
      ),
      _broadcast(
        7,
        AudienceSelector.users(const ['alice']),
        source: const BroadcastScope.group(4),
      ),
    ]);
    final c = _container(fake);
    await c.read(clBroadcastsMasterProvider.future);

    List<int> ids(BroadcastScope scope) => c
        .read(clBroadcastsForScopeProvider(scope))
        .requireValue
        .map((b) => b.id)
        .toList();

    // Newest first: a later id was sent later.
    expect(ids(const BroadcastScope.all()), [4, 1]);
    expect(ids(const BroadcastScope.group(3)), [3, 2]);
    expect(ids(const BroadcastScope.event(9)), [5]);
    expect(ids(const BroadcastScope.member('alice')), [6]);
    expect(ids(const BroadcastScope.group(4)), [7]);
  });

  test('Issue 198: the broadcasts master loads every page', () async {
    final fake = _PagedBroadcasts(45);
    final c = _container(fake);

    final map = await c.read(clBroadcastsMasterProvider.future);

    expect(map.length, 45);
  });

  test('Issue 256: a coach who is not an admin lists no broadcasts', () async {
    final fake = _PagedBroadcasts(3);
    final c = _container(
      fake,
      user: const UserInfo(
        username: 'coach',
        displayName: 'coach',
        status: UserStatus.active,
        isSuperAdmin: false,
        roles: UserRoles(isCoach: true),
      ),
    );

    final map = await c.read(clBroadcastsMasterProvider.future);

    expect(map, isEmpty);
    expect(fake.listCalls, 0, reason: 'GET /broadcasts is admin only');
  });
}

/// Lists [count] broadcasts, a page of at most `limit` at a time.
class _PagedBroadcasts extends Fake implements BroadcastSource {
  _PagedBroadcasts(this.count);

  final int count;

  /// How many pages were asked for.
  int listCalls = 0;

  @override
  Future<PaginatedList<Broadcast>> listBroadcasts({
    int offset = 0,
    int limit = 20,
  }) async {
    listCalls++;
    final end = (offset + limit).clamp(0, count);
    return PaginatedList<Broadcast>(
      items: [
        for (var id = offset; id < end; id++)
          Broadcast(
            id: id,
            audienceSelector: const AudienceSelector.allUsers(),
            payload: const {},
            sentAtUtc: DateTime.utc(2026),
            status: BroadcastStatus.sent,
            recipientCount: 1,
          ),
      ],
      total: count,
      offset: offset,
      limit: limit,
    );
  }
}

/// Lists the given broadcasts in one page.
class _ListedBroadcasts extends Fake implements BroadcastSource {
  _ListedBroadcasts(this.items);

  final List<Broadcast> items;

  @override
  Future<PaginatedList<Broadcast>> listBroadcasts({
    int offset = 0,
    int limit = 20,
  }) async => PaginatedList<Broadcast>(
    items: offset == 0 ? items : const [],
    total: items.length,
    offset: offset,
    limit: limit,
  );
}

/// A sent broadcast [id] to [audience], sent [id] minutes into 2026, carrying
/// [source] as `payload.source` when given.
Broadcast _broadcast(
  int id,
  AudienceSelector audience, {
  BroadcastScope? source,
}) => Broadcast(
  id: id,
  audienceSelector: audience,
  payload: {
    'v': 1,
    'type': 'broadcast.text',
    'data': {'text': 'message $id'},
    if (source != null) 'source': source.toPayload(),
  },
  sentAtUtc: DateTime.utc(2026, 1, 1, 0, id),
  status: BroadcastStatus.sent,
  recipientCount: 1,
);
