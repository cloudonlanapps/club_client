// Credit UI flows for integration tests (club_core#101, #102, #104).
//
// Owns:
//   * openCreditSheetFromProfile — from a member's profile (admin/coach:
//     /memberzone/users/<u>; the member: /memberzone/profile), tap the
//     CreditChip after the name; lands on the CreditView sheet.
//   * closeCreditSheet — dismiss the sheet (modal pop).
//   * sheetTotal / statementTotals — read what the sheet shows.
//   * addCreditInSheet / transferInSheet / reverseInSheet — drive the
//     admin actions and their dialogs.
//   * chipCredits — the number on a CreditChip for a member, if shown.
//   * pickerTile — a picker tile (Assign / Assign Trial) by username.

import 'package:cl_club_credits/src/views/credit_view.dart' show CreditView;
import 'package:cl_club_credits/src/widgets/credit_account_menu.dart'
    show CreditAccountMenu;
import 'package:cl_club_credits/src/widgets/credit_account_row.dart'
    show CreditAccountRow;
import 'package:cl_club_credits/src/widgets/credit_action_dialog.dart'
    show CreditActionDialog;
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
    show CreditCountChip, CreditFormFields, UserSelectionTile;

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

/// Opens Add credit in the sheet (or uses a dialog already open, e.g. a
/// pre-filled one), fills it and saves. [programmeId] null keeps what the
/// form holds (General unless pre-filled).
Future<void> addCreditInSheet(
  WidgetTester tester, {
  required int credits,
  int? programmeId,
  bool? trial,
  String reason = 'workflow credit',
}) async {
  if (find.byType(CreditActionDialog).evaluate().isEmpty) {
    invokeShadButton(
      tester,
      find.widgetWithText(ShadButton, 'Add credit'),
      reason: 'Add credit',
    );
    await settle(tester);
  }
  await fillCreditDialog(
    tester,
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

/// Opens [action] ("Extend", "Reverse", "Transfer") on the sheet's package
/// matching [where], fills it with [text] and saves.
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
  await fillCreditDialog(tester, text: text);
}

/// Fills the open credit dialog's text fields [text] and form [values],
/// then saves and waits for it to close.
Future<void> fillCreditDialog(
  WidgetTester tester, {
  Map<String, String> text = const {},
  Map<String, dynamic> values = const {},
}) async {
  final dialog = find.byType(CreditActionDialog);
  await waitFor(
    tester,
    () => dialog.evaluate().isNotEmpty,
    description: 'a credit dialog to open',
  );
  for (final entry in text.entries) {
    final field = find.descendant(
      of: dialog,
      matching: find.byWidgetPredicate(
        (w) => w is ShadInputFormField && w.id == entry.key,
      ),
    );
    await tester.enterText(field, entry.value);
  }
  if (values.isNotEmpty) {
    tester
        .state<ShadFormState>(
          find.descendant(of: dialog, matching: find.byType(ShadForm)),
        )
        .setValue(values);
  }
  await tester.pump();
  invokeShadButton(
    tester,
    find.descendant(
      of: dialog,
      matching: find.widgetWithText(ShadButton, 'Save'),
    ),
    reason: 'credit dialog Save',
  );
  await settle(tester);
  await waitFor(
    tester,
    () {
      final toast = firstErrorToastMessage(tester);
      if (toast != null) throw TestFailure('credit action refused: $toast');
      return dialog.evaluate().isEmpty;
    },
    description: 'the credit dialog to close after saving',
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
