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

ProviderContainer _container(BroadcastSource broadcasts) {
  final c = ProviderContainer(
    overrides: [
      secureClientProvider.overrideWith(
        (ref) async => _buildClient(broadcasts),
      ),
      currentUserProvider.overrideWith((ref) => _admin()),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('ClBroadcastsMasterNotifier', () {
    test('Issue 737: sendText without email omits the email fields', () async {
      final fake = _FakeBroadcasts();
      final c = _container(fake);
      await c.read(clBroadcastsMasterProvider.future);

      await c.read(clBroadcastsMasterProvider.notifier).sendText('hello');

      final call = fake.calls.single;
      expect(call['email'], isFalse);
      expect(call['emailSubject'], isNull);
      expect(call['emailBody'], isNull);
      expect(
        (call['audienceSelector'] as AudienceSelector).kind,
        AudienceKind.allUsers,
      );
    });

    test(
      'Issue 737: sendText with email forwards subject and body=text',
      () async {
        final fake = _FakeBroadcasts();
        final c = _container(fake);
        await c.read(clBroadcastsMasterProvider.future);

        await c
            .read(clBroadcastsMasterProvider.notifier)
            .sendText(
              'hello',
              email: true,
              emailSubject: 'Broadcast Message from EXC',
            );

        final call = fake.calls.single;
        expect(call['email'], isTrue);
        expect(call['emailSubject'], 'Broadcast Message from EXC');
        expect(call['emailBody'], 'hello');
      },
    );

    test(
      'Issue 737: sendToGroup targets the group with email body=text',
      () async {
        final fake = _FakeBroadcasts();
        final c = _container(fake);
        await c.read(clBroadcastsMasterProvider.future);

        await c
            .read(clBroadcastsMasterProvider.notifier)
            .sendToGroup(
              42,
              'practice moved',
              email: true,
              emailSubject: 'Message for U12',
            );

        final call = fake.calls.single;
        final selector = call['audienceSelector'] as AudienceSelector;
        expect(selector.kind, AudienceKind.group);
        expect(selector.groupId, 42);
        expect(call['email'], isTrue);
        expect(call['emailSubject'], 'Message for U12');
        expect(call['emailBody'], 'practice moved');
      },
    );

    test(
      'Issue 737: sendToGroup without email omits the email fields',
      () async {
        final fake = _FakeBroadcasts();
        final c = _container(fake);
        await c.read(clBroadcastsMasterProvider.future);

        await c
            .read(clBroadcastsMasterProvider.notifier)
            .sendToGroup(42, 'practice moved');

        final call = fake.calls.single;
        expect(call['email'], isFalse);
        expect(call['emailSubject'], isNull);
        expect(call['emailBody'], isNull);
      },
    );
  });
}
