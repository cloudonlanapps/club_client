import 'package:cl_club_forms/cl_club_forms.dart' show TwoColumnGrid;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clEvaluationsMasterProvider, evaluationIncompleteItemIds;
import 'package:club_sdk_2/club_sdk_2.dart' show EvaluationStaffView;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton, ConfirmDialog;

import '../constants/evaluation_view_sizes.dart';
import '../constants/evaluation_view_strings.dart';
import '../models/evaluation_step.dart';
import '../utils/evaluation_error_message.dart';
import '../utils/evaluation_lifecycle.dart';
import 'evaluation_titled_card.dart';
import 'evaluation_transfer_dialog.dart';

/// **Review Management**: the owner's actions on [evaluation] by its status
/// ([EvaluationStep.forStatus]), formatted as the profile's User
/// Management card — a two-column grid of outline action buttons.
///
/// **Finalize** first runs [prepareSave] (the form's own check) and calls
/// the server only when it passes; the server's `INCOMPLETE` items go to
/// [onIncomplete]. Publish and Delete ask first.
class EvaluationManagementCard extends ConsumerStatefulWidget {
  /// The actions on [evaluation].
  const EvaluationManagementCard({
    required this.evaluation,
    required this.prepareSave,
    required this.onIncomplete,
    required this.onDeleted,
    required this.onTransferred,
    super.key,
  });

  /// The evaluation, as its owner reads it.
  final EvaluationStaffView evaluation;

  /// Writes pending answers and checks the form; `false` stops the save.
  final Future<bool> Function() prepareSave;

  /// Told of the items the server says are incomplete.
  final ValueChanged<List<int>> onIncomplete;

  /// Called once the draft is deleted.
  final VoidCallback onDeleted;

  /// Called once the evaluation is handed to another coach.
  final VoidCallback onTransferred;

  /// Buttons per row of the grid.
  static const int columns = 2;

  @override
  ConsumerState<EvaluationManagementCard> createState() =>
      EvaluationManagementCardState();
}

/// State of [EvaluationManagementCard]: the action in flight.
class EvaluationManagementCardState
    extends ConsumerState<EvaluationManagementCard> {
  /// The step running, if any.
  EvaluationStep? running;

  /// Shows [message]; [failed] makes it destructive.
  void toast(String message, {bool failed = false}) {
    final text = Text(message);
    ShadToaster.of(context).show(
      failed
          ? ShadToast.destructive(description: text)
          : ShadToast(description: text),
    );
  }

  /// What [step] needs before it runs: the form's check, a confirmation, or
  /// the coach to transfer to. `false` stops it; a transfer's coach is
  /// returned.
  Future<(bool, String?)> prepare(EvaluationStep step) async {
    switch (step) {
      case EvaluationStep.save:
        final ready = await widget.prepareSave();
        if (!ready && mounted) {
          toast(EvaluationViewStrings.completeMarked, failed: true);
        }
        return (ready, null);
      case EvaluationStep.publish || EvaluationStep.delete:
        final publish = step == EvaluationStep.publish;
        final ok = await ConfirmDialog.show(
          context,
          title: publish
              ? EvaluationViewStrings.publishTitle
              : EvaluationViewStrings.deleteTitle,
          message: publish
              ? EvaluationViewStrings.publishMessage
              : EvaluationViewStrings.deleteMessage,
          confirmLabel: step.label,
          destructive: step.isDestructive,
        );
        return (ok, null);
      case EvaluationStep.transfer:
        final owner = await showEvaluationTransferDialog(
          context,
          ref,
          widget.evaluation,
        );
        return (owner != null, owner);
      case EvaluationStep.unpublish || EvaluationStep.revert:
        return (true, null);
    }
  }

  /// Runs [step].
  Future<void> run(EvaluationStep step) async {
    final (go, owner) = await prepare(step);
    if (!go || !mounted) return;
    setState(() => running = step);
    try {
      await EvaluationLifecycle.perform(
        step,
        id: widget.evaluation.id,
        owner: owner,
        notifier: ref.read(clEvaluationsMasterProvider.notifier),
      );
      if (!mounted) return;
      toast(step.doneMessage);
      if (step == EvaluationStep.delete) widget.onDeleted();
      if (step == EvaluationStep.transfer) widget.onTransferred();
    } on Object catch (e) {
      final incomplete = evaluationIncompleteItemIds(e);
      if (incomplete != null) widget.onIncomplete(incomplete);
      if (mounted) toast(EvaluationErrorMessage.of(e), failed: true);
    } finally {
      if (mounted) setState(() => running = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = EvaluationStep.forStatus(widget.evaluation.status);
    final busy = running != null;
    final buttons = <Widget>[
      for (final step in steps)
        ActionButton(
          label: step.label,
          loading: running == step,
          onPressed: busy ? null : () => run(step),
        ),
    ];
    // Keep the grid's last row as wide as the others, as the profile does.
    while (buttons.length % EvaluationManagementCard.columns != 0) {
      buttons.add(
        const IgnorePointer(
          child: Opacity(opacity: 0, child: ActionButton(label: '')),
        ),
      );
    }
    return EvaluationTitledCard(
      title: EvaluationViewStrings.reviewManagement,
      child: TwoColumnGrid(
        spacing: EvaluationViewSizes.cardItemGap,
        runSpacing: EvaluationViewSizes.cardItemGap,
        singleColumnBreakpoint: 0,
        children: buttons,
      ),
    );
  }
}
