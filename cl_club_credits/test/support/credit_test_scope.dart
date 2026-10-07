import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class StubAuth extends AuthNotifier {
  StubAuth(this.user);
  final UserPrivate? user;
  @override
  Future<UserPrivate?> build() async => user;
}

class StubAccounts extends ClCreditAccountsMasterNotifier {
  StubAccounts(this.accounts);
  final Map<String, List<CreditAccount>> accounts;
  final List<String> opened = [];

  /// When set, every action throws this instead of applying.
  Exception? error;

  @override
  Future<List<CreditAccount>> build(String arg) async =>
      accounts[arg] ?? const [];

  @override
  Future<CreditAccount> openAccount({
    required int credits,
    required DateTime validFromUtc,
    required DateTime validUntilUtc,
    required String reason,
    int? eventId,
    bool isTrial = false,
  }) async {
    opened.add('$username $credits $eventId $isTrial $reason');
    return account('NEW00001', membername: username, balance: credits);
  }

  /// The package actions made, as `<action> <accountId> <reason>`.
  final List<String> actions = [];

  @override
  Future<CreditAccount> extendValidity(
    String accountId, {
    required DateTime validUntilUtc,
    required String reason,
  }) async {
    final refusal = error;
    if (refusal != null) throw refusal;
    actions.add('extend $accountId $reason');
    return account(accountId, membername: username, balance: 1);
  }

  @override
  Future<CreditAccount> reverseGrant(
    String accountId, {
    required int credits,
    required String reason,
  }) async {
    final refusal = error;
    if (refusal != null) throw refusal;
    actions.add('reverse $accountId $reason');
    return account(accountId, membername: username, balance: 0);
  }

  @override
  Future<CreditTransferResult> transfer(
    String accountId, {
    required int penalty,
    required DateTime validFromUtc,
    required DateTime validUntilUtc,
    required String reason,
  }) async {
    actions.add('transfer $accountId $reason');
    return CreditTransferResult(
      source: account(accountId, membername: username, balance: 0),
    );
  }
}

/// Counts the routes on the navigator above the home route: every dialog
/// and sheet is one.
class RouteStack extends NavigatorObserver {
  /// Modal routes currently open.
  int depth = 0;

  /// Modal routes ever pushed.
  int pushed = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute == null) return;
    depth++;
    pushed++;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => depth--;
}

class StubEntries extends ClCreditEntriesMasterNotifier {
  StubEntries(this.entries);
  final Map<String, List<CreditEntry>> entries;
  @override
  Future<CreditStatement> build(String arg) async =>
      (entries: entries[arg] ?? const <CreditEntry>[], hasMore: false);
}

class StubUsers extends ClUsersMasterNotifier {
  StubUsers(this.users);
  final Map<String, UserInfo> users;
  @override
  Future<Map<String, UserInfo>> build() async => users;
}

class StubMyEvents extends ClMyEventsMasterNotifier {
  @override
  Future<List<Event>> build(String arg) async => const [];
}

class StubEvents extends ClEventsMasterNotifier {
  @override
  Future<Map<int, Event>> build() async => const {};
}

UserPrivate viewer(
  String username, {
  bool admin = false,
  bool coach = false,
}) => UserPrivate(
  username: username,
  displayName: username,
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: UserRoles(isAdmin: admin, isCoach: coach),
  createdAtUtc: DateTime.utc(2024),
);

CreditAccount account(
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

/// A provider scope with credit on (unless [creditSystem] says otherwise),
/// [user] logged in, and the credit masters stubbed.
Widget creditScope({
  required Widget child,
  UserPrivate? user,
  bool? creditSystem = true,
  Map<String, List<CreditAccount>> accounts = const {},
  Map<String, List<CreditEntry>> entries = const {},
  Map<String, UserInfo> users = const {},
  StubAccounts Function()? accountsNotifier,
  RouteStack? routes,
}) {
  return ProviderScope(
    overrides: [
      creditSystemProvider.overrideWithValue(creditSystem),
      authStateProvider.overrideWith(() => StubAuth(user)),
      clCreditAccountsMasterProvider.overrideWith(
        accountsNotifier ?? () => StubAccounts(accounts),
      ),
      clCreditEntriesMasterProvider.overrideWith(() => StubEntries(entries)),
      clUsersMasterProvider.overrideWith(() => StubUsers(users)),
      clMyEventsMasterProvider.overrideWith(StubMyEvents.new),
      clEventsMasterProvider.overrideWith(StubEvents.new),
    ],
    child: ShadApp(
      navigatorObservers: [?routes],
      home: Scaffold(body: child),
    ),
  );
}
