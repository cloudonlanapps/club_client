import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

/// Capabilities fake: answers with [creditSystem], or never answers when
/// [pending] (the "not known yet" state).
class FakeCapabilities extends Fake implements CapabilitiesSource {
  FakeCapabilities({this.creditSystem = true, this.pending = false});

  final bool creditSystem;
  final bool pending;

  @override
  Future<Capabilities> getCapabilities() {
    if (pending) return Future<Capabilities>.delayed(const Duration(days: 1));
    return Future.value(Capabilities(creditSystem: creditSystem));
  }
}

/// `/mycredits` fake over in-memory accounts and a statement, recording
/// every call.
class FakeMyCredits extends Fake implements MyCreditsSource {
  final Map<String, List<CreditAccount>> accounts = {};
  final Map<String, List<CreditEntry>> entries = {};
  final List<String> calls = [];

  @override
  Future<List<CreditAccount>> listMyAccounts(
    String username, {
    CreditAccountState? state,
    bool includeClosed = false,
  }) async {
    calls.add('accounts($username, includeClosed: $includeClosed)');
    return List.of(accounts[username] ?? const []);
  }

  @override
  Future<PaginatedList<CreditEntry>> listMyEntries(
    String username, {
    String? accountId,
    int? eventId,
    DateTime? fromUtc,
    DateTime? toUtc,
    EntryOrder? order,
    int offset = 0,
    int limit = 50,
  }) async {
    calls.add('entries($username, ${order?.name}, $offset, $limit)');
    final all = entries[username] ?? const <CreditEntry>[];
    final page = all.skip(offset).take(limit).toList();
    return PaginatedList(
      items: page,
      total: all.length,
      offset: offset,
      limit: limit,
    );
  }
}

/// `/credits` fake: records admin calls and applies [openAccount] to the
/// paired [FakeMyCredits] store.
class FakeCredits extends Fake implements CreditSource {
  FakeCredits(this.store);

  final FakeMyCredits store;
  final List<String> calls = [];

  @override
  Future<CreditAccount> openAccount({
    required String membername,
    required int credits,
    required DateTime validFromUtc,
    required DateTime validUntilUtc,
    required String reason,
    int? eventId,
    bool isTrial = false,
  }) async {
    calls.add('open($membername, $credits, $eventId, trial: $isTrial)');
    final account = creditAccount(
      'NEW${store.accounts[membername]?.length ?? 0}',
      membername: membername,
      balance: credits,
      eventId: eventId,
      isTrial: isTrial,
    );
    store.accounts.putIfAbsent(membername, () => []).add(account);
    return account;
  }

  @override
  Future<CreditAccount> extendValidity(
    String accountId, {
    required DateTime validUntilUtc,
    required String reason,
  }) async {
    calls.add('extend($accountId)');
    return creditAccount(accountId, membername: '?', balance: 0);
  }

  @override
  Future<CreditAccount> reverseGrant(
    String accountId, {
    required String reason,
    int? credits,
  }) async {
    calls.add('reverse($accountId, $credits)');
    return creditAccount(accountId, membername: '?', balance: 0);
  }

  @override
  Future<CreditTransferResult> transfer(
    String accountId, {
    required int penalty,
    required DateTime validFromUtc,
    required DateTime validUntilUtc,
    required String reason,
  }) async {
    calls.add('transfer($accountId, $penalty)');
    return CreditTransferResult(
      source: creditAccount(accountId, membername: '?', balance: 0),
    );
  }
}

/// A credit account fixture; usable unless [state] says otherwise.
CreditAccount creditAccount(
  String accountId, {
  required String membername,
  required int balance,
  int? eventId,
  bool isTrial = false,
  CreditAccountState state = CreditAccountState.usable,
}) => CreditAccount(
  accountId: accountId,
  membername: membername,
  kind: eventId == null ? CreditAccountKind.general : CreditAccountKind.event,
  eventId: eventId,
  isTrial: isTrial,
  balance: balance,
  validFromUtc: DateTime.utc(2026),
  validUntilUtc: DateTime.utc(2027),
  usable: state == CreditAccountState.usable && balance > 0,
  state: state,
  openedAtUtc: DateTime.utc(2026),
);

/// A statement line fixture.
CreditEntry creditEntry(
  int id, {
  required String membername,
  int amount = -1,
  CreditEntryType type = CreditEntryType.sessionDeduction,
  int? totalAfter,
}) => CreditEntry(
  id: id,
  accountId: 'ACC00001',
  membername: membername,
  amount: amount,
  entryType: type,
  reason: '',
  createdAtUtc: DateTime.utc(2026, 9, id),
  totalAfter: totalAfter,
);
