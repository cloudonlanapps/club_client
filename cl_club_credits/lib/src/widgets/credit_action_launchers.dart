import 'package:cl_remote_store/cl_remote_store.dart'
    show clCreditAccountsMasterProvider, clEventsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show CreditAccount, EventType;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show
        CreditExtendForm,
        CreditExtendFormState,
        CreditGrantForm,
        CreditGrantFormState,
        CreditProgrammeOption,
        CreditReverseForm,
        CreditReverseFormState,
        CreditTransferForm,
        CreditTransferFormState;

import '../models/credit_form_helpers.dart';
import 'credit_action_dialog.dart';

/// Admin credit actions (club_core#101), each a form in a
/// [CreditActionDialog]. They resolve to true once the action succeeded;
/// the accounts master bumps `creditsVersion`, so every credit view
/// refreshes itself.

/// ➕ Add credit for [username]: a new account. [programmeId] and [trial]
/// pre-fill it (the pickers do, club_core#105).
Future<bool> showCreditGrantDialog(
  BuildContext context,
  WidgetRef ref, {
  required String username,
  int? programmeId,
  bool trial = false,
}) async {
  final events = ref.read(clEventsMasterProvider).valueOrNull ?? const {};
  final programmes = [
    for (final e in events.values)
      if (e.type == EventType.programme && e.isActive)
        CreditProgrammeOption(id: e.id, title: e.title),
  ]..sort((a, b) => a.title.compareTo(b.title));
  final key = GlobalKey<CreditGrantFormState>();
  final done = await showShadDialog<bool>(
    context: context,
    builder: (context) => CreditActionDialog(
      title: 'Add credit',
      form: CreditGrantForm(
        key: key,
        programmes: programmes,
        initialValues: buildCreditGrantFormInitialValues(
          today: DateTime.now(),
          programmeId: programmeId,
          trial: trial,
        ),
      ),
      validate: () => key.currentState?.validate(),
      onSubmit: (values) => CreditAccountFormSubmit.openAccount(
        values: values,
        notifier: ref.read(clCreditAccountsMasterProvider(username).notifier),
      ),
    ),
  );
  return done ?? false;
}

/// 📅 Extend [account]'s validity.
Future<bool> showCreditExtendDialog(
  BuildContext context,
  WidgetRef ref, {
  required CreditAccount account,
}) async {
  final key = GlobalKey<CreditExtendFormState>();
  final until = account.validUntilUtc.toLocal();
  final done = await showShadDialog<bool>(
    context: context,
    builder: (context) => CreditActionDialog(
      title: 'Extend',
      form: CreditExtendForm(
        key: key,
        currentValidUntil: DateTime(until.year, until.month, until.day),
      ),
      validate: () => key.currentState?.validate(),
      onSubmit: (values) => CreditAccountFormSubmit.extendValidity(
        account.accountId,
        values: values,
        notifier: ref.read(
          clCreditAccountsMasterProvider(account.membername).notifier,
        ),
      ),
    ),
  );
  return done ?? false;
}

/// ↶ Reverse unspent credit on [account], capped at its balance (R59).
Future<bool> showCreditReverseDialog(
  BuildContext context,
  WidgetRef ref, {
  required CreditAccount account,
}) async {
  final key = GlobalKey<CreditReverseFormState>();
  final done = await showShadDialog<bool>(
    context: context,
    builder: (context) => CreditActionDialog(
      title: 'Reverse',
      form: CreditReverseForm(key: key, unspent: account.balance),
      validate: () => key.currentState?.validate(),
      onSubmit: (values) => CreditAccountFormSubmit.reverseGrant(
        account.accountId,
        values: values,
        notifier: ref.read(
          clCreditAccountsMasterProvider(account.membername).notifier,
        ),
      ),
    ),
  );
  return done ?? false;
}

/// ⇄ Close [account] and move what survives a penalty into a new general
/// account: how a programme's credit is settled.
Future<bool> showCreditTransferDialog(
  BuildContext context,
  WidgetRef ref, {
  required CreditAccount account,
}) async {
  final key = GlobalKey<CreditTransferFormState>();
  final done = await showShadDialog<bool>(
    context: context,
    builder: (context) => CreditActionDialog(
      title: 'Transfer',
      form: CreditTransferForm(
        key: key,
        balance: account.balance,
        today: DateTime.now(),
      ),
      validate: () => key.currentState?.validate(),
      onSubmit: (values) => CreditAccountFormSubmit.transfer(
        account.accountId,
        values: values,
        notifier: ref.read(
          clCreditAccountsMasterProvider(account.membername).notifier,
        ),
      ),
    ),
  );
  return done ?? false;
}
