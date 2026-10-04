import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_secure_client.dart';

Inquiry _inquiry(
  int id, {
  InquiryKind kind = InquiryKind.contact,
  bool handled = false,
}) => Inquiry(
  id: id,
  kind: kind,
  name: 'Sender $id',
  email: 'sender$id@example.com',
  message: 'Message $id',
  createdAtUtc: DateTime.utc(2026, 9, id),
  handledAtUtc: handled ? DateTime.utc(2026, 9, 20) : null,
  handledBy: handled ? 'admin' : null,
);

/// An in-memory inbox that answers like the server: newest first, filtered
/// by kind and handled state, paged by offset and limit.
class _FakeInquiries extends Fake implements InquirySource {
  _FakeInquiries(this.rows);

  final List<Inquiry> rows;
  final List<Map<String, Object?>> listCalls = [];
  final List<int> deleted = [];

  @override
  Future<PaginatedList<Inquiry>> listInquiries({
    InquiryKind? kind,
    bool? handled,
    int offset = 0,
    int limit = 20,
  }) async {
    listCalls.add({
      'kind': kind,
      'handled': handled,
      'offset': offset,
      'limit': limit,
    });
    final matching = rows
        .where((r) => kind == null || r.kind == kind)
        .where((r) => handled == null || r.isHandled == handled)
        .toList();
    return PaginatedList<Inquiry>(
      items: matching.skip(offset).take(limit).toList(),
      total: matching.length,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<Inquiry> setInquiryHandled(int id, {required bool handled}) async {
    final i = rows.indexWhere((r) => r.id == id);
    final updated = rows[i].copyWith(
      handledAtUtc: () => handled ? DateTime.utc(2026, 9, 28) : null,
      handledBy: () => handled ? 'admin' : null,
    );
    rows[i] = updated;
    return updated;
  }

  @override
  Future<void> deleteInquiry(int id) async {
    deleted.add(id);
    rows.removeWhere((r) => r.id == id);
  }
}

UserInfo _user({bool admin = true}) => UserInfo(
  username: 'viewer',
  displayName: 'viewer',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: UserRoles(isAdmin: admin, isMember: !admin),
);

ProviderContainer _container(_FakeInquiries fake, {bool admin = true}) {
  final c = ProviderContainer(
    overrides: [
      secureClientProvider.overrideWith(
        (ref) async => fakeSecureClient(inquiries: fake),
      ),
      currentUserProvider.overrideWith((ref) => _user(admin: admin)),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  group('Issue 21: ClInquiriesMasterNotifier', () {
    test('Issue 21: opens on the unhandled inbox with its count', () async {
      final fake = _FakeInquiries([
        _inquiry(3),
        _inquiry(2, handled: true),
        _inquiry(1, kind: InquiryKind.interest),
      ]);
      final c = _container(fake);

      final inbox = await c.read(clInquiriesMasterProvider.future);

      expect(inbox.filter, InquiryFilter.open);
      expect(inbox.page.items.map((i) => i.id), [3, 1]);
      expect(inbox.unhandledCount, 2);
      expect(fake.listCalls.first['handled'], isFalse);
    });

    test('Issue 21: a non-admin gets an empty inbox and no call', () async {
      final fake = _FakeInquiries([_inquiry(1)]);
      final c = _container(fake, admin: false);

      final inbox = await c.read(clInquiriesMasterProvider.future);

      expect(inbox.page.items, isEmpty);
      expect(inbox.unhandledCount, 0);
      expect(fake.listCalls, isEmpty);
    });

    test('Issue 21: setFilter forwards kind and handled, keeps the '
        'unhandled count', () async {
      final fake = _FakeInquiries([
        _inquiry(3, handled: true),
        _inquiry(2, kind: InquiryKind.interest, handled: true),
        _inquiry(1),
      ]);
      final c = _container(fake);
      await c.read(clInquiriesMasterProvider.future);

      await c
          .read(clInquiriesMasterProvider.notifier)
          .setFilter(
            const InquiryFilter(kind: InquiryKind.contact, handled: true),
          );

      final inbox = c.read(clInquiriesMasterProvider).requireValue;
      expect(inbox.page.items.map((i) => i.id), [3]);
      expect(inbox.unhandledCount, 1);
      expect(
        fake.listCalls.any(
          (call) =>
              call['kind'] == InquiryKind.contact && call['handled'] == true,
        ),
        isTrue,
      );
    });

    test('Issue 21: next and previous page move the offset', () async {
      final fake = _FakeInquiries([
        for (var i = 30; i > 0; i--) _inquiry(i),
      ]);
      final c = _container(fake);
      final notifier = c.read(clInquiriesMasterProvider.notifier);
      await c.read(clInquiriesMasterProvider.future);

      await notifier.nextPage();
      var inbox = c.read(clInquiriesMasterProvider).requireValue;
      expect(inbox.page.offset, inquiryPageSize);
      expect(inbox.page.items.first.id, 30 - inquiryPageSize);

      await notifier.previousPage();
      inbox = c.read(clInquiriesMasterProvider).requireValue;
      expect(inbox.page.offset, 0);
    });

    test('Issue 21: marking handled drops the row from the open inbox and '
        'lowers the count', () async {
      final fake = _FakeInquiries([_inquiry(2), _inquiry(1)]);
      final c = _container(fake);
      await c.read(clInquiriesMasterProvider.future);

      final updated = await c
          .read(clInquiriesMasterProvider.notifier)
          .setHandled(2, handled: true);

      expect(updated.isHandled, isTrue);
      final inbox = c.read(clInquiriesMasterProvider).requireValue;
      expect(inbox.page.items.map((i) => i.id), [1]);
      expect(inbox.page.total, 1);
      expect(inbox.unhandledCount, 1);
    });

    test('Issue 21: reopening in the all-states view replaces the row in '
        'place and raises the count', () async {
      final fake = _FakeInquiries([_inquiry(2, handled: true), _inquiry(1)]);
      final c = _container(fake);
      final notifier = c.read(clInquiriesMasterProvider.notifier);
      await c.read(clInquiriesMasterProvider.future);
      await notifier.setFilter(const InquiryFilter());

      await notifier.setHandled(2, handled: false);

      final inbox = c.read(clInquiriesMasterProvider).requireValue;
      expect(inbox.page.items.map((i) => i.id), [2, 1]);
      expect(inbox.page.items.first.isHandled, isFalse);
      expect(inbox.unhandledCount, 2);
    });

    test('Issue 21: delete removes the row and an open one from the '
        'count', () async {
      final fake = _FakeInquiries([_inquiry(2), _inquiry(1)]);
      final c = _container(fake);
      await c.read(clInquiriesMasterProvider.future);

      await c.read(clInquiriesMasterProvider.notifier).deleteInquiry(2);

      expect(fake.deleted, [2]);
      final inbox = c.read(clInquiriesMasterProvider).requireValue;
      expect(inbox.page.items.map((i) => i.id), [1]);
      expect(inbox.page.total, 1);
      expect(inbox.unhandledCount, 1);
    });

    test('Issue 21: the unhandled count provider follows the master', () async {
      final fake = _FakeInquiries([_inquiry(2), _inquiry(1)]);
      final c = _container(fake);
      await c.read(clInquiriesMasterProvider.future);
      expect(c.read(clUnhandledInquiryCountProvider), 2);

      await c
          .read(clInquiriesMasterProvider.notifier)
          .setHandled(1, handled: true);

      expect(c.read(clUnhandledInquiryCountProvider), 1);
    });
  });
}
