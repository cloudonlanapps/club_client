import 'package:cl_remote_store/cl_remote_store.dart'
    show clEvaluationsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show EvaluationStaffView, EvaluationStatus;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show
        EditableSectionCard,
        EvaluationPeriodForm,
        EvaluationPeriodFormState,
        EvaluationStartChoice;

import '../constants/evaluation_view_strings.dart';
import '../models/evaluation_period_form_submit.dart';
import '../utils/evaluation_error_message.dart';
import '../utils/evaluation_names.dart';
import '../utils/start_review_choices.dart';
import 'evaluation_period_rows.dart';

/// The owner's Review Period section (Section-wise Editors): the event and
/// the period stated ([EvaluationPeriodRows]), edited in place while a
/// draft through an `EditableSectionCard` hosting the ui_lib
/// `EvaluationPeriodForm`.
///
/// The pencil edits both: the event — *General*, or one the start dialog
/// would offer for this member (`StartReviewChoices.eventsFor`, the
/// owner's active events the member is enrolled in), the current one kept
/// even when no longer among them — and the period. The adapter
/// (`EvaluationPeriodFormSubmit.updateReviewPeriod`) sends only what
/// changed. A server refusal (`DUPLICATE_EVALUATION`, `NOT_ELIGIBLE`,
/// `PERIOD_IN_FUTURE`, `EVENT_NOT_FOUND`) shows inline under the form,
/// which stays open.
class EvaluationPeriodCard extends ConsumerStatefulWidget {
  /// The Review Period section of [evaluation].
  const EvaluationPeriodCard({required this.evaluation, super.key});

  /// The evaluation, as its owner reads it.
  final EvaluationStaffView evaluation;

  @override
  ConsumerState<EvaluationPeriodCard> createState() =>
      EvaluationPeriodCardState();
}

/// State of [EvaluationPeriodCard]: the Review Period form's key.
class EvaluationPeriodCardState extends ConsumerState<EvaluationPeriodCard> {
  /// The period form, attached while editing.
  final GlobalKey<EvaluationPeriodFormState> formKey =
      GlobalKey<EvaluationPeriodFormState>();

  /// Writes the event and the period; `true` once saved. A refusal shows
  /// inline.
  Future<bool> save(Map<String, dynamic> values) async {
    final toaster = ShadToaster.of(context);
    try {
      await EvaluationPeriodFormSubmit.updateReviewPeriod(
        evaluation: widget.evaluation,
        values: values,
        notifier: ref.read(clEvaluationsMasterProvider.notifier),
      );
      toaster.show(
        const ShadToast(description: Text(EvaluationViewStrings.periodUpdated)),
      );
      return true;
    } on Object catch (e) {
      formKey.currentState?.showErrors(
        formError: EvaluationErrorMessage.of(e),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.evaluation;
    final draft = e.status == EvaluationStatus.draft;
    final events = draft
        ? StartReviewChoices.eventsFor(
            ref,
            coach: e.effectiveOwner,
            member: e.createdFor,
          )
        : const <EvaluationStartChoice>[];
    final eventId = e.eventId;
    final current = eventId == null
        ? null
        : (
            id: eventId,
            label: EvaluationNames.event(
              ref,
              member: e.createdFor,
              eventId: eventId,
            ),
          );
    return EditableSectionCard<Map<String, dynamic>>(
      title: EvaluationViewStrings.reviewPeriod,
      canEdit: draft,
      isEmpty: EvaluationPeriodRows.isEmptyFor(
        eventId: e.eventId,
        startUtc: e.periodStartUtc,
        endUtc: e.periodEndUtc,
      ),
      emptyHint: EvaluationViewStrings.noPeriod,
      read: EvaluationPeriodRows(
        member: e.createdFor,
        eventId: e.eventId,
        startUtc: e.periodStartUtc,
        endUtc: e.periodEndUtc,
      ),
      editBuilder: ({required enabled}) => EvaluationPeriodForm(
        key: formKey,
        events: events,
        initialValues: buildEvaluationPeriodFormInitialValues(
          e,
          event: current,
        ),
        enabled: enabled,
      ),
      onValidate: () => formKey.currentState?.validate(),
      isDirty: () => formKey.currentState?.isDirty ?? false,
      onSave: save,
    );
  }
}
