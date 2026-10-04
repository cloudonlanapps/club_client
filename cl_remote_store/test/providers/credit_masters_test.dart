import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_credit_sources.dart';
import '../support/fake_secure_client.dart';

const _member = 'credit_member';

/// Attendance fake whose mark and clear succeed without a record.
class _Attendance extends Fake implements AttendanceSource {
  @override
  Future<List<AttendanceRecord>> getAttendanceForOccurrence(
    int eventId,
    DateTime occurrenceTimeUtc,
  ) async => const [];

  @override
  Future<AttendanceMarkReport> markAttendance(
    int eventId,
    DateTime occurrenceTimeUtc,
    List<AttendanceMarkRecord> records,
  ) async => const AttendanceMarkReport();
}

({ProviderContainer container, FakeMyCredits myCredits, FakeCredits credits})
_setUp({bool creditSystem = true, bool pending = false}) {
  final myCredits = FakeMyCredits();
  final credits = FakeCredits(myCredits);
  final container = ProviderContainer(
    overrides: [
      secureClientProvider.overrideWith(
        (ref) async => fakeSecureClient(
          capabilities: FakeCapabilities(
            creditSystem: creditSystem,
            pending: pending,
          ),
          myCredits: myCredits,
          credits: credits,
          attendance: _Attendance(),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return (container: container, myCredits: myCredits, credits: credits);
}

/// Keeps an auto-dispose provider alive and waits for its settled value.
Future<T> _settled<T>(
  ProviderContainer container,
  ProviderListenable<AsyncValue<T>> provider,
) async {
  final sub = container.listen(provider, (_, _) {});
  addTearDown(sub.close);
  for (var i = 0; i < 50; i++) {
    final value = container.read(provider);
    if (value.hasValue && !value.isLoading) return value.requireValue;
    await Future<void>.delayed(Duration.zero);
  }
  throw StateError('$provider did not settle');
}

void main() {
  group('Issue 102: credit providers follow the capability', () {
    test('Issue 102: creditSystemProvider reads the capability', () async {
      final on = _setUp();
      await on.container.read(capabilitiesProvider.future);
      expect(on.container.read(creditSystemProvider), isTrue);

      final off = _setUp(creditSystem: false);
      await off.container.read(capabilitiesProvider.future);
      expect(off.container.read(creditSystemProvider), isFalse);
    });

    test('Issue 102: credit off makes no credit call and no total', () async {
      final s = _setUp(creditSystem: false);
      await s.container.read(capabilitiesProvider.future);

      final accounts = await _settled(
        s.container,
        clCreditAccountsMasterProvider(_member),
      );

      expect(accounts, isEmpty);
      expect(s.myCredits.calls, isEmpty);
      expect(s.container.read(clMemberCreditTotalProvider(_member)), isNull);
    });

    test('Issue 102: unknown capability makes no credit call', () async {
      final s = _setUp(pending: true);

      final accounts = await _settled(
        s.container,
        clCreditAccountsMasterProvider(_member),
      );

      expect(accounts, isEmpty);
      expect(s.myCredits.calls, isEmpty);
      expect(s.container.read(creditSystemProvider), isNull);
    });

    test('Issue 102: the total sums usable balances only', () async {
      final s = _setUp();
      s.myCredits.accounts[_member] = [
        creditAccount('GEN00001', membername: _member, balance: 5),
        creditAccount('PRG00001', membername: _member, balance: 7, eventId: 9),
        creditAccount(
          'OLD00001',
          membername: _member,
          balance: 4,
          state: CreditAccountState.expired,
        ),
      ];
      await s.container.read(capabilitiesProvider.future);

      await _settled(s.container, clCreditAccountsMasterProvider(_member));

      expect(s.container.read(clMemberCreditTotalProvider(_member)), 12);
      expect(s.myCredits.calls, [
        'accounts($_member, includeClosed: true)',
      ]);
    });
  });

  group('Issue 101: admin actions refresh every credit view', () {
    test('Issue 101: opening an account refetches the accounts', () async {
      final s = _setUp();
      await s.container.read(capabilitiesProvider.future);
      await _settled(s.container, clCreditAccountsMasterProvider(_member));

      await s.container
          .read(clCreditAccountsMasterProvider(_member).notifier)
          .openAccount(
            credits: 10,
            validFromUtc: DateTime.utc(2026, 9),
            validUntilUtc: DateTime.utc(2026, 12),
            reason: 'season',
            eventId: 9,
          );
      final accounts = await _settled(
        s.container,
        clCreditAccountsMasterProvider(_member),
      );

      expect(s.credits.calls, ['open($_member, 10, 9, trial: false)']);
      expect(accounts.single.balance, 10);
      expect(s.container.read(clMemberCreditTotalProvider(_member)), 10);
    });

    test('Issue 101: an attendance mark bumps creditsVersion', () async {
      final s = _setUp();
      final key = (eventId: 9, occurrenceTimeUtc: DateTime.utc(2026, 9, 1));
      await _settled(s.container, clAttendancesMasterProvider(key));
      final before = s.container.read(clResourceVersionProvider).creditsVersion;

      await s.container
          .read(clAttendancesMasterProvider(key).notifier)
          .markAttendance([
            const AttendanceMarkRecord(
              membername: _member,
              status: AttendanceStatus.present,
            ),
          ]);

      expect(
        s.container.read(clResourceVersionProvider).creditsVersion,
        greaterThan(before),
      );
    });
  });

  group('Issue 101: the statement pages newest first', () {
    test('Issue 101: loadMore appends the next page', () async {
      final s = _setUp();
      s.myCredits.entries[_member] = [
        for (var i = 1; i <= creditStatementPageSize + 5; i++)
          creditEntry(i, membername: _member, totalAfter: 100 - i),
      ];
      await s.container.read(capabilitiesProvider.future);

      final first = await _settled(
        s.container,
        clCreditEntriesMasterProvider(_member),
      );
      expect(first.entries, hasLength(creditStatementPageSize));
      expect(first.hasMore, isTrue);

      await s.container
          .read(clCreditEntriesMasterProvider(_member).notifier)
          .loadMore();
      final all = s.container
          .read(clCreditEntriesMasterProvider(_member))
          .requireValue;

      expect(all.entries, hasLength(creditStatementPageSize + 5));
      expect(all.hasMore, isFalse);
      const pageSize = creditStatementPageSize;
      expect(s.myCredits.calls, [
        'entries($_member, newestFirst, 0, $pageSize)',
        'entries($_member, newestFirst, $pageSize, $pageSize)',
      ]);
    });
  });
}
