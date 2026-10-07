import 'package:cl_club_credits/cl_club_credits.dart' show CreditView;
import 'package:cl_club_events/src/widgets/assign_trial_dialog.dart';
import 'package:cl_club_events/src/widgets/funded_user_selection_dialog.dart';
import 'package:cl_club_forms/cl_club_forms.dart'
    show CreditFormFields, CreditGrantForm;
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:cl_remote_store/src/utils/bump_credits_version.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/user_selection_tile.dart'
    show UserSelectionTile;
import 'package:ui_lib/ui_lib.dart' show CreditCountChip, PickerUser;

import '../support/credit_scope.dart';

const _broke = 'broke';
const _users = [PickerUser(username: _broke, displayName: 'Broke')];

/// The club's usable accounts, as the server would hold them: Add credit
/// writes here, and the pickers read it back.
class Ledger {
  final Map<String, List<CreditAccount>> usable = {};
}

class LedgerAccounts extends ClCreditAccountsMasterNotifier {
  LedgerAccounts(this.ledger);
  final Ledger ledger;

  @override
  Future<List<CreditAccount>> build(String arg) async =>
      ledger.usable[arg] ?? const [];

  @override
  Future<CreditAccount> openAccount({
    required int credits,
    required DateTime validFromUtc,
    required DateTime validUntilUtc,
    required String reason,
    int? eventId,
    bool isTrial = false,
  }) async {
    final opened = account(
      username,
      credits,
      eventId: eventId,
      isTrial: isTrial,
    );
    ledger.usable.putIfAbsent(username, () => []).add(opened);
    bumpCreditsVersion(ref);
    return opened;
  }
}

class LedgerUsableAccounts extends ClUsableCreditAccountsNotifier {
  LedgerUsableAccounts(this.ledger);
  final Ledger ledger;

  @override
  Future<Map<String, List<CreditAccount>>> build() async {
    ref.watch(clResourceVersionProvider.select((s) => s.creditsVersion));
    return {
      for (final entry in ledger.usable.entries) entry.key: [...entry.value],
    };
  }
}

class StubUsers extends ClUsersMasterNotifier {
  @override
  Future<Map<String, UserInfo>> build() async => const {
    _broke: UserInfo(
      publicId: _broke,
      username: _broke,
      displayName: 'Broke',
      firstName: 'Broke',
      lastName: 'Member',
      status: UserStatus.active,
      isSuperAdmin: false,
      roles: UserRoles(),
    ),
  };
}

/// Modal routes open above the home route.
class RouteStack extends NavigatorObserver {
  int depth = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) depth++;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => depth--;
}

/// Opens [picker] in a dialog, as the enrollment action bar does.
Future<RouteStack> _openPicker(
  WidgetTester tester,
  Widget picker, {
  Size surface = const Size(900, 1400),
}) async {
  final ledger = Ledger();
  final routes = RouteStack();
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        creditSystemProvider.overrideWithValue(true),
        authStateProvider.overrideWith(
          () => StubAuth(person('an_admin', admin: true)),
        ),
        clEventsMasterProvider.overrideWith(
          () => StubEvents({
            programmeId: event(programmeId, EventType.programme),
          }),
        ),
        clUsersMasterProvider.overrideWith(StubUsers.new),
        clCreditAccountsMasterProvider.overrideWith(
          () => LedgerAccounts(ledger),
        ),
        clUsableCreditAccountsProvider.overrideWith(
          () => LedgerUsableAccounts(ledger),
        ),
      ],
      child: ShadApp(
        navigatorObservers: [routes],
        home: Scaffold(
          body: Builder(
            builder: (context) => ShadButton(
              onPressed: () => showShadDialog<void>(
                context: context,
                builder: (context) => picker,
              ),
              child: const Text('Open picker'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open picker'));
  await tester.pumpAndSettle();
  return routes;
}

Future<void> _tapAddChip(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('Add credit'));
  await tester.pumpAndSettle();
}

Future<void> _saveCredit(WidgetTester tester, int credits) async {
  Future<void> enter(String id, String text) => tester.enterText(
    find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id),
    text,
  );
  await enter(CreditFormFields.creditsId, '$credits');
  await enter(CreditFormFields.reasonId, 'picker credit');
  await tester.tap(find.widgetWithText(ShadButton, 'Save'));
  await tester.pumpAndSettle();
}

/// A narrow phone.
const Size _phone = Size(320, 640);

/// An unfunded member shows the zero chip and "+", side by side; the zero
/// chip opens the credit sheet, as any number chip does.
Future<void> _expectZeroChipBesidePlus(
  WidgetTester tester,
  RouteStack routes,
) async {
  final zero = find.bySemanticsLabel('Credit 0');
  final plus = find.bySemanticsLabel('Add credit');
  expect(zero, findsOneWidget);
  expect(plus, findsOneWidget);
  expect(
    tester.getCenter(zero).dy,
    moreOrLessEquals(tester.getCenter(plus).dy, epsilon: 1),
  );
  expect(tester.getTopRight(zero).dx, lessThan(tester.getTopLeft(plus).dx));

  await tester.tap(zero);
  await tester.pumpAndSettle();
  expect(routes.depth, 2);
  expect(find.byType(CreditView), findsOneWidget);
  expect(find.byType(CreditGrantForm), findsNothing);
}

Map<String, dynamic> _grantValues(WidgetTester tester) =>
    tester.widget<CreditGrantForm>(find.byType(CreditGrantForm)).initialValues;

void main() {
  group('Issue 41: the "+" chip in Assign Users', () {
    const picker = FundedUserSelectionDialog(
      title: 'Assign Users',
      users: _users,
      eventId: programmeId,
    );

    testWidgets('Issue 41: "+" opens Add credit over the picker, with the '
        'programme pre-filled and no sheet behind it', (tester) async {
      final routes = await _openPicker(tester, picker);
      expect(routes.depth, 1);

      await _tapAddChip(tester);

      // The picker and Add credit: nothing in between.
      expect(routes.depth, 2);
      expect(find.byType(CreditView), findsNothing);
      expect(find.byType(ShadSheet), findsNothing);
      expect(_grantValues(tester)[CreditFormFields.programmeId], programmeId);
      expect(_grantValues(tester)[CreditFormFields.trialId], isFalse);
    });

    testWidgets(
      'Issue 41: after Save the picker shows the credit of the member '
      'and the member can be selected',
      (tester) async {
        final routes = await _openPicker(tester, picker);
        expect(
          tester
              .widget<UserSelectionTile>(find.byType(UserSelectionTile))
              .onTap,
          isNull,
        );

        await _tapAddChip(tester);
        await _saveCredit(tester, 3);

        expect(routes.depth, 1, reason: 'back in the picker');
        expect(find.byType(CreditGrantForm), findsNothing);
        expect(find.bySemanticsLabel('Add credit'), findsNothing);
        expect(find.bySemanticsLabel('Credit 3'), findsOneWidget);
        expect(
          tester
              .widget<UserSelectionTile>(find.byType(UserSelectionTile))
              .onTap,
          isNotNull,
        );
      },
    );

    testWidgets('Issue 41: the chip that shows a number opens the credit '
        'sheet over the picker', (tester) async {
      final routes = await _openPicker(tester, picker);
      await _tapAddChip(tester);
      await _saveCredit(tester, 3);

      await tester.tap(find.byType(CreditCountChip));
      await tester.pumpAndSettle();

      expect(routes.depth, 2);
      expect(find.byType(CreditView), findsOneWidget);
    });
  });

  for (final (name, picker) in <(String, Widget)>[
    (
      'Assign Users',
      const FundedUserSelectionDialog(
        title: 'Assign Users',
        users: _users,
        eventId: programmeId,
      ),
    ),
    (
      'Assign Trial',
      const AssignTrialDialogContent(
        eventId: programmeId,
        currentEnrollments: {},
      ),
    ),
  ]) {
    group('Issue 41: a member with no usable credit in $name', () {
      testWidgets('Issue 41: $name shows a zero chip beside "+", and the '
          'zero chip opens the credit sheet', (tester) async {
        final routes = await _openPicker(tester, picker);
        await _expectZeroChipBesidePlus(tester, routes);
      });

      testWidgets('Issue 41: $name fits both chips at phone width', (
        tester,
      ) async {
        await _openPicker(tester, picker, surface: _phone);

        expect(tester.takeException(), isNull);
        expect(find.bySemanticsLabel('Credit 0'), findsOneWidget);
        final plus = find.bySemanticsLabel('Add credit');
        expect(tester.getTopRight(plus).dx, lessThanOrEqualTo(_phone.width));
      });
    });
  }

  group('Issue 41: the "+" chip in Assign Trial', () {
    const picker = AssignTrialDialogContent(
      eventId: programmeId,
      currentEnrollments: {},
    );

    testWidgets('Issue 41: "+" opens Add credit over the trial picker, with '
        'the programme and Trial pre-set and no sheet behind it', (
      tester,
    ) async {
      final routes = await _openPicker(tester, picker);

      await _tapAddChip(tester);

      expect(routes.depth, 2);
      expect(find.byType(CreditView), findsNothing);
      expect(find.byType(ShadSheet), findsNothing);
      expect(_grantValues(tester)[CreditFormFields.programmeId], programmeId);
      expect(_grantValues(tester)[CreditFormFields.trialId], isTrue);
    });

    testWidgets('Issue 41: after Save the trial picker shows the '
        'trial credit of the member, who can be picked', (tester) async {
      final routes = await _openPicker(tester, picker);
      await _tapAddChip(tester);
      await _saveCredit(tester, 1);

      expect(routes.depth, 1, reason: 'back in the trial picker');
      expect(find.bySemanticsLabel('Add credit'), findsNothing);
      expect(find.bySemanticsLabel('Credit 0'), findsNothing);
      expect(find.bySemanticsLabel('Credit 1'), findsOneWidget);

      // Picking the member closes the picker with them as the result.
      await tester.tap(find.text(_broke));
      await tester.pumpAndSettle();
      expect(routes.depth, 0);
    });
  });
}
