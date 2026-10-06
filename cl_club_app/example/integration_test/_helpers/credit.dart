// Credit UI flows for integration tests (club_core#101, #102, #104).
//
// Owns:
//   * openCreditSheetFromProfile — from a member's profile (admin/coach:
//     /memberzone/users/<u>; the member: /memberzone/profile), tap the
//     CreditChip after the name; lands on the CreditView sheet.
//   * closeCreditSheet — dismiss the sheet (modal pop).
//   * sheetTotal / statementTotals — read what the sheet shows.
//   * addCreditInSheet / packageActionInSheet — drive the admin actions,
//     whose forms open in place inside the sheet (club_client#41).
//   * addCreditFromAddChip — tap a picker's "+" chip and save the Add
//     credit dialog it opens alone, with no sheet (club_client#41).
//   * chipCredits — the number on a CreditChip for a member, if shown.
//   * pickerTile — a picker tile (Assign / Assign Trial) by username.

import 'package:cl_club_credits/src/views/credit_view.dart' show CreditView;
import 'package:cl_club_credits/src/widgets/credit_account_menu.dart'
    show CreditAccountMenu;
import 'package:cl_club_credits/src/widgets/credit_account_row.dart'
    show CreditAccountRow;
import 'package:cl_club_credits/src/widgets/credit_action_dialog.dart'
    show CreditActionDialog;
import 'package:cl_club_credits/src/widgets/credit_action_panel.dart'
    show CreditActionPanel;
import 'package:cl_club_credits/src/widgets/credit_chip.dart' show CreditChip;
import 'package:cl_club_credits/src/widgets/credit_entry_row.dart'
    show CreditEntryRow;
import 'package:cl_club_members/src/widgets/profile_credit_line.dart'
    show ProfileCreditLine;
import 'package:club_sdk_2/club_sdk_2.dart' show CreditAccount;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show CreditCountChip, CreditFormFields, CreditGrantForm, UserSelectionTile;

import 'auth.dart';
import 'forms.dart';
import 'pump.dart';

/// Opens [username]'s credit sheet from their profile. [self] uses the
/// member's own profile route. Returns once the CreditView has loaded.
Future<void> openCreditSheetFromProfile(
  WidgetTester tester, {
  required String username,
  bool self = false,
}) async {
  await go(
    tester,
    self ? '/memberzone/profile' : '/memberzone/users/$username',
  );
  final chip = find.descendant(
    of: find.byType(ProfileCreditLine),
    matching: find.byType(CreditCountChip),
  );
  await waitFor(
    tester,
    () => chip.evaluate().isNotEmpty,
    description: 'the credit chip on the profile of $username',
  );
  tester.widget<CreditCountChip>(chip).onTap!.call();
  await settle(tester);
  await waitFor(
    tester,
    () => find.byType(CreditView).evaluate().isNotEmpty,
    description: 'the credit view for $username to open',
  );
}

/// Closes the credit sheet.
Future<void> closeCreditSheet(WidgetTester tester) async {
  Navigator.of(tester.element(find.byType(CreditView))).pop();
  await settle(tester);
}

/// The usable total in the open sheet's header, once it reads [expected].
Future<void> expectSheetTotal(WidgetTester tester, int expected) async {
  await waitFor(
    tester,
    () => find
        .descendant(
          of: find.byType(CreditView),
          matching: find.bySemanticsLabel('Credit $expected'),
        )
        .evaluate()
        .isNotEmpty,
    description: 'the credit view total to read $expected',
  );
}

/// The statement's running totals, newest first, once there are [atLeast].
Future<List<int?>> statementTotals(
  WidgetTester tester, {
  int atLeast = 1,
}) async {
  await waitFor(
    tester,
    () => find.byType(CreditEntryRow).evaluate().length >= atLeast,
    description: 'at least $atLeast statement lines',
  );
  return [
    for (final row in tester.widgetList<CreditEntryRow>(
      find.byType(CreditEntryRow),
    ))
      row.entry.totalAfter,
  ];
}

/// The statement's signed amounts, newest first.
List<int> statementAmounts(WidgetTester tester) => [
  for (final row in tester.widgetList<CreditEntryRow>(
    find.byType(CreditEntryRow),
  ))
    row.entry.amount,
];

/// Opens Add credit in the sheet, fills the form it shows in place and
/// saves. [programmeId] null keeps what the form holds (General).
Future<void> addCreditInSheet(
  WidgetTester tester, {
  required int credits,
  int? programmeId,
  bool? trial,
  String reason = 'workflow credit',
}) async {
  invokeShadButton(
    tester,
    find.descendant(
      of: find.byType(CreditView),
      matching: find.widgetWithText(ShadButton, 'Add credit'),
    ),
    reason: 'Add credit',
  );
  await settle(tester);
  expectNoCreditDialogOverSheet();
  await fillCreditForm(
    tester,
    host: find.byType(CreditActionPanel),
    text: {
      CreditFormFields.creditsId: '$credits',
      CreditFormFields.reasonId: reason,
    },
    values: {
      CreditFormFields.programmeId: ?programmeId,
      CreditFormFields.trialId: ?trial,
    },
  );
}

/// Taps the "+" chip of [username] under [within] (a picker) and saves the
/// Add credit dialog it opens: alone over the picker, with no credit sheet,
/// pre-filled with [programmeId] and [trial] (club_client#41).
Future<void> addCreditFromAddChip(
  WidgetTester tester, {
  required String username,
  required Finder within,
  required int credits,
  required int programmeId,
  required bool trial,
  String reason = 'workflow credit',
}) async {
  final chip = find.descendant(
    of: find.descendant(
      of: within,
      matching: find.byWidgetPredicate(
        (w) => w is CreditChip && w.username == username,
      ),
    ),
    matching: find.byWidgetPredicate((w) => w is CreditCountChip && w.add),
  );
  await waitFor(
    tester,
    () => chip.evaluate().isNotEmpty,
    description: 'the add-credit chip of $username',
  );
  tester.widget<CreditCountChip>(chip).onTap!();
  await settle(tester);
  final dialog = find.byType(CreditActionDialog);
  await waitFor(
    tester,
    () => dialog.evaluate().isNotEmpty,
    description: 'Add credit to open for $username',
  );
  expect(
    find.byType(CreditView),
    findsNothing,
    reason: 'the "+" chip opens Add credit alone, with no sheet behind it',
  );
  final prefilled = tester
      .widget<CreditGrantForm>(
        find.descendant(of: dialog, matching: find.byType(CreditGrantForm)),
      )
      .initialValues;
  expect(prefilled[CreditFormFields.programmeId], programmeId);
  expect(prefilled[CreditFormFields.trialId], trial);
  await fillCreditForm(
    tester,
    host: dialog,
    text: {
      CreditFormFields.creditsId: '$credits',
      CreditFormFields.reasonId: reason,
    },
  );
}

/// Opens [action] ("Extend", "Reverse", "Transfer") on the sheet's package
/// matching [where], fills the form it shows in place with [text] and
/// saves.
Future<void> packageActionInSheet(
  WidgetTester tester, {
  required bool Function(CreditAccount account) where,
  required String action,
  required Map<String, String> text,
}) async {
  final row = find.byWidgetPredicate(
    (w) => w is CreditAccountRow && where(w.account),
  );
  await waitFor(
    tester,
    () => row.evaluate().isNotEmpty,
    description: 'the package to $action',
  );
  final menu = find.descendant(
    of: row,
    matching: find.byType(CreditAccountMenu),
  );
  final button = find.descendant(
    of: menu,
    matching: find.byType(ShadIconButton),
  );
  tester.widget<ShadIconButton>(button).onPressed!.call();
  await settle(tester);
  invokeShadButton(
    tester,
    find.widgetWithText(ShadButton, action),
    reason: action,
  );
  await settle(tester);
  expectNoCreditDialogOverSheet();
  await fillCreditForm(
    tester,
    host: find.byType(CreditActionPanel),
    text: text,
  );
}

/// A credit action opened in the sheet pushes no dialog over it
/// (club_client#41).
void expectNoCreditDialogOverSheet() => expect(
  find.byType(CreditActionDialog),
  findsNothing,
  reason: 'credit actions open inside the sheet, not in a dialog over it',
);

/// Fills the credit form shown in [host] (the in-place panel of the sheet,
/// or the Add credit dialog): its text fields [text] and form [values].
/// Then saves and waits for the form to close.
Future<void> fillCreditForm(
  WidgetTester tester, {
  required Finder host,
  Map<String, String> text = const {},
  Map<String, dynamic> values = const {},
}) async {
  await waitFor(
    tester,
    () => host.evaluate().isNotEmpty,
    description: 'a credit form to open',
  );
  for (final entry in text.entries) {
    final field = find.descendant(
      of: host,
      matching: find.byWidgetPredicate(
        (w) => w is ShadInputFormField && w.id == entry.key,
      ),
    );
    await tester.enterText(field, entry.value);
  }
  if (values.isNotEmpty) {
    tester
        .state<ShadFormState>(
          find.descendant(of: host, matching: find.byType(ShadForm)),
        )
        .setValue(values);
  }
  await tester.pump();
  invokeShadButton(
    tester,
    find.descendant(
      of: host,
      matching: find.widgetWithText(ShadButton, 'Save'),
    ),
    reason: 'credit form Save',
  );
  await settle(tester);
  await waitFor(
    tester,
    () {
      final toast = firstErrorToastMessage(tester);
      if (toast != null) throw TestFailure('credit action refused: $toast');
      return host.evaluate().isEmpty;
    },
    description: 'the credit form to close after saving',
  );
}

/// The number on the CreditChip shown for [username] under [within], or
/// null when there is none.
int? chipCredits(WidgetTester tester, String username, {Finder? within}) {
  final chips = find.byWidgetPredicate(
    (w) => w is CreditChip && w.username == username,
  );
  final scoped = within == null
      ? chips
      : find.descendant(of: within, matching: chips);
  if (scoped.evaluate().isEmpty) return null;
  final count = find.descendant(
    of: scoped.first,
    matching: find.byType(CreditCountChip),
  );
  if (count.evaluate().isEmpty) return null;
  return tester.widget<CreditCountChip>(count).credits;
}

/// The picker tile (Assign) for [username].
UserSelectionTile pickerTile(WidgetTester tester, String username) =>
    tester.widget<UserSelectionTile>(
      find.byWidgetPredicate(
        (w) => w is UserSelectionTile && w.user.username == username,
      ),
    );
