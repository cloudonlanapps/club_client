import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class StubAuth extends AuthNotifier {
  StubAuth(this.user);
  final UserPrivate? user;
  @override
  Future<UserPrivate?> build() async => user;
}

class StubEvents extends ClEventsMasterNotifier {
  StubEvents(this.events);
  final Map<int, Event> events;
  @override
  Future<Map<int, Event>> build() async => events;
}

class StubRoster extends ClEventCreditRosterNotifier {
  StubRoster(this.rows);
  final Map<String, MemberCreditStatus> rows;
  @override
  Future<Map<String, MemberCreditStatus>> build(int arg) async => rows;
}

class StubAccounts extends ClCreditAccountsMasterNotifier {
  StubAccounts(this.accounts);
  final Map<String, List<CreditAccount>> accounts;
  @override
  Future<List<CreditAccount>> build(String arg) async =>
      accounts[arg] ?? const [];
}

class StubUsableAccounts extends ClUsableCreditAccountsNotifier {
  StubUsableAccounts(this.accounts);
  final Map<String, List<CreditAccount>> accounts;
  @override
  Future<Map<String, List<CreditAccount>>> build() async => accounts;
}

const programmeId = 9;
const campId = 8;

Event event(int id, EventType type) => Event(
  id: id,
  version: 1,
  title: '${type.name} $id',
  description: '',
  type: type,
  visibility: Visibility.public,
  venueId: 1,
  startTimeUtc: DateTime.now().toUtc().add(const Duration(days: 1)),
  endTimeUtc: DateTime.now().toUtc().add(const Duration(days: 1, hours: 1)),
  createdAtUtc: DateTime.utc(2026),
  updatedAtUtc: DateTime.utc(2026),
);

UserPrivate person(String username, {bool admin = false, bool coach = false}) =>
    UserPrivate(
      username: username,
      displayName: username,
      status: UserStatus.active,
      isSuperAdmin: false,
      roles: UserRoles(isAdmin: admin, isCoach: coach),
      createdAtUtc: DateTime.utc(2024),
    );

/// The organizer of [staffed] (club_core#136).
const staffOrganizer = 'the_organizer';

/// The coach assigned to [staffed], who is not its organizer (#136).
const staffCoach = 'assigned_coach';

/// [event] with [staffOrganizer] as organizer and [staffCoach] assigned.
Event staffed(int id, EventType type) => event(id, type).copyWith(
  organizerName: () => staffOrganizer,
  coachNames: () => const [staffCoach],
);

CreditAccount account(
  String membername,
  int balance, {
  int? eventId,
  bool isTrial = false,
}) => CreditAccount(
  accountId: 'ACC${membername.hashCode.abs() % 100000}',
  membername: membername,
  kind: eventId == null ? CreditAccountKind.general : CreditAccountKind.event,
  eventId: eventId,
  isTrial: isTrial,
  balance: balance,
  validFromUtc: DateTime.utc(2026),
  validUntilUtc: DateTime.utc(2027),
  usable: balance > 0,
  state: balance > 0 ? CreditAccountState.usable : CreditAccountState.empty,
  openedAtUtc: DateTime.utc(2026),
);

MemberCreditStatus rosterRow(
  String membername, {
  int usable = 0,
  int bound = 0,
}) => MemberCreditStatus(
  membername: membername,
  usableCredits: usable,
  boundCredits: bound,
  blocked: usable < 1,
);

/// A scope with credit [creditSystem], a camp and a programme (or
/// [events], when given), and the credit providers stubbed.
Widget creditScope({
  required Widget child,
  UserPrivate? user,
  bool? creditSystem = true,
  Map<int, Event>? events,
  Map<String, MemberCreditStatus> roster = const {},
  Map<String, List<CreditAccount>> accounts = const {},
  List<Override> extra = const [],
}) {
  return ProviderScope(
    overrides: [
      creditSystemProvider.overrideWithValue(creditSystem),
      authStateProvider.overrideWith(() => StubAuth(user)),
      clEventsMasterProvider.overrideWith(
        () => StubEvents(
          events ??
              {
                programmeId: event(programmeId, EventType.programme),
                campId: event(campId, EventType.camp),
              },
        ),
      ),
      clEventCreditRosterProvider.overrideWith(() => StubRoster(roster)),
      clCreditAccountsMasterProvider.overrideWith(() => StubAccounts(accounts)),
      clUsableCreditAccountsProvider.overrideWith(
        () => StubUsableAccounts(accounts),
      ),
      ...extra,
    ],
    child: ShadApp(home: Scaffold(body: child)),
  );
}
