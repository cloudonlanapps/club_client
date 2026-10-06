import 'package:cl_remote_store/cl_remote_store.dart'
    show clCreditAccountsMasterProvider, clEventsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show CreditAccount, Event, EventType;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

import '../models/credit_action_kind.dart';
import '../models/credit_form_helpers.dart';
import 'credit_action_dialog.dart';
import 'credit_action_panel.dart';

/// One admin credit action (club_core#101), connected: the `ui_lib` form of
/// its [kind], and the call it makes through [username]'s accounts master,
/// which bumps `creditsVersion` so every credit view refreshes itself.
///
/// [CreditActionForm.inPlace] shows it inside the credit view;
/// [CreditActionForm.dialog] is the content of a dialog, for Add credit
/// opened alone from a picker (club_client#41).
class CreditActionForm extends ConsumerStatefulWidget {
  /// The action as a dialog's content; it pops `true` once it succeeded.
  const CreditActionForm.dialog({
    required this.kind,
    required this.username,
    this.account,
    this.programmeId,
    this.trial = false,
    super.key,
  }) : onClose = null,
       assert(
         kind == CreditActionKind.grant || account != null,
         'Extend, Reverse and Transfer act on an account.',
       );

  /// The action shown where it is built; [onClose] runs on Cancel and once
  /// it succeeded.
  const CreditActionForm.inPlace({
    required this.kind,
    required this.username,
    required VoidCallback this.onClose,
    this.account,
    this.programmeId,
    this.trial = false,
    super.key,
  }) : assert(
         kind == CreditActionKind.grant || account != null,
         'Extend, Reverse and Transfer act on an account.',
       );

  final CreditActionKind kind;

  /// The member whose credit this acts on.
  final String username;

  /// The package Extend, Reverse and Transfer act on.
  final CreditAccount? account;

  /// Pre-fills Add credit with a programme (the pickers do, club_core#105).
  final int? programmeId;

  /// Pre-sets Add credit's trial flag.
  final bool trial;

  /// Closes the in-place form; null in a dialog, which pops itself.
  final VoidCallback? onClose;

  @override
  ConsumerState<CreditActionForm> createState() => CreditActionFormState();
}

class CreditActionFormState extends ConsumerState<CreditActionForm> {
  final grantKey = GlobalKey<CreditGrantFormState>();
  final extendKey = GlobalKey<CreditExtendFormState>();
  final reverseKey = GlobalKey<CreditReverseFormState>();
  final transferKey = GlobalKey<CreditTransferFormState>();

  /// The day the form opened: its date defaults do not move on a rebuild.
  final DateTime today = DateTime.now();

  late final Map<String, dynamic> grantInitialValues =
      buildCreditGrantFormInitialValues(
        today: today,
        programmeId: widget.programmeId,
        trial: widget.trial,
      );

  Map<String, dynamic>? validate() => switch (widget.kind) {
    CreditActionKind.grant => grantKey.currentState?.validate(),
    CreditActionKind.extend => extendKey.currentState?.validate(),
    CreditActionKind.reverse => reverseKey.currentState?.validate(),
    CreditActionKind.transfer => transferKey.currentState?.validate(),
  };

  Future<void> submit(Map<String, dynamic> values) {
    final notifier = ref.read(
      clCreditAccountsMasterProvider(widget.username).notifier,
    );
    final accountId = widget.account?.accountId ?? '';
    return switch (widget.kind) {
      CreditActionKind.grant => CreditAccountFormSubmit.openAccount(
        values: values,
        notifier: notifier,
      ),
      CreditActionKind.extend => CreditAccountFormSubmit.extendValidity(
        accountId,
        values: values,
        notifier: notifier,
      ),
      CreditActionKind.reverse => CreditAccountFormSubmit.reverseGrant(
        accountId,
        values: values,
        notifier: notifier,
      ),
      CreditActionKind.transfer => CreditAccountFormSubmit.transfer(
        accountId,
        values: values,
        notifier: notifier,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    // Held for as long as the form is open: the mutation runs on this
    // master, which nothing else watches when Add credit opens alone.
    ref.watch(clCreditAccountsMasterProvider(widget.username));
    final account = widget.account;
    final form = switch (widget.kind) {
      CreditActionKind.grant => CreditGrantForm(
        key: grantKey,
        programmes: [
          for (final e
              in ref.watch(clEventsMasterProvider).valueOrNull?.values ??
                  const <Event>[])
            if (e.type == EventType.programme && e.isActive)
              CreditProgrammeOption(id: e.id, title: e.title),
        ]..sort((a, b) => a.title.compareTo(b.title)),
        initialValues: grantInitialValues,
      ),
      CreditActionKind.extend => CreditExtendForm(
        key: extendKey,
        currentValidUntil: DateUtils.dateOnly(
          account!.validUntilUtc.toLocal(),
        ),
      ),
      CreditActionKind.reverse => CreditReverseForm(
        key: reverseKey,
        unspent: account!.balance,
      ),
      CreditActionKind.transfer => CreditTransferForm(
        key: transferKey,
        balance: account!.balance,
        today: today,
      ),
    };
    final onClose = widget.onClose;
    if (onClose == null) {
      return CreditActionDialog(
        title: widget.kind.title,
        form: form,
        validate: validate,
        onSubmit: submit,
      );
    }
    return CreditActionPanel(
      title: widget.kind.title,
      form: form,
      validate: validate,
      onSubmit: submit,
      onClose: onClose,
    );
  }
}
