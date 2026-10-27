import 'package:cl_remote_store/cl_remote_store.dart'
    show clEvaluationsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show EvaluationStaffView, EvaluationStatus, EvaluationTemplate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart'
    show EvaluationFillBody, EvaluationFillBodyState, EvaluationLayoutEntry;
import 'package:ui_lib/ui_lib.dart' show PdfAction;

import '../constants/evaluation_view_sizes.dart';
import '../constants/evaluation_view_strings.dart';
import '../models/evaluation_answer_adapter.dart';
import '../models/evaluation_layout_adapter.dart';
import '../utils/evaluation_answer_writer.dart';
import '../utils/evaluation_autosave.dart';
import '../utils/evaluation_error_toast.dart';
import '../utils/evaluation_names.dart';
import 'evaluation_edit_top_bar.dart';
import 'evaluation_evidence_slot.dart';
import 'evaluation_head_card.dart';
import 'evaluation_info_card.dart';
import 'evaluation_management_card.dart';
import 'evaluation_page.dart';
import 'evaluation_period_card.dart';

/// The owner's editor of [evaluation]; see `EvaluationEditView`.
class EvaluationEditBody extends ConsumerStatefulWidget {
  /// Edits [evaluation].
  const EvaluationEditBody({
    required this.evaluation,
    required this.template,
    required this.onBack,
    required this.onDeleted,
    required this.onTransferred,
    required this.pdfAction,
    super.key,
  });

  /// The evaluation, as its owner reads it.
  final EvaluationStaffView evaluation;

  /// Its template.
  final EvaluationTemplate template;

  /// Leaves the view, without asking: answers autosave.
  final VoidCallback onBack;

  /// Called once the draft is deleted.
  final VoidCallback onDeleted;

  /// Called once the evaluation is handed to another coach.
  final VoidCallback onTransferred;

  /// What a downloaded PDF — the member copy or evidence — is handed to.
  final PdfAction pdfAction;

  @override
  ConsumerState<EvaluationEditBody> createState() => EvaluationEditBodyState();
}

/// State of [EvaluationEditBody]: the fill form and the autosave.
class EvaluationEditBodyState extends ConsumerState<EvaluationEditBody> {
  /// The fill form.
  final GlobalKey<EvaluationFillBodyState> fillKey =
      GlobalKey<EvaluationFillBodyState>();

  /// Writes each answer to the evaluation as last read or written.
  late final EvaluationAnswerWriter writer;

  /// Writes each answer once it settles.
  late final EvaluationAutosave autosave;

  /// The template's items and sections, as the fill form takes them.
  late List<EvaluationLayoutEntry> layout;

  @override
  void initState() {
    super.initState();
    writer = EvaluationAnswerWriter(
      notifier: ref.read(clEvaluationsMasterProvider.notifier),
      latest: widget.evaluation,
      context: () => mounted ? context : null,
      fill: () => fillKey.currentState,
    );
    autosave = EvaluationAutosave(
      delay: EvaluationViewSizes.autosaveDelay,
      write: writer.write,
      // Clearing an answer with evidence asks, so never mid-typing.
      holdWhileTyping: writer.clearsEvidence,
      onError: (e) => showEvaluationErrorToast(
        mounted ? context : null,
        e,
        fallback: EvaluationViewStrings.answerFailed,
      ),
    );
    readTemplate();
  }

  @override
  void didUpdateWidget(EvaluationEditBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    writer.latest = widget.evaluation;
    if (oldWidget.template != widget.template) readTemplate();
  }

  @override
  void dispose() {
    autosave.dispose();
    super.dispose();
  }

  /// Lays out the template for the fill form.
  void readTemplate() {
    final t = widget.template;
    layout = EvaluationLayoutAdapter.fromTemplate(t.layout, t.items);
    writer.items = {
      for (final i in EvaluationLayoutEntry.flatten(layout)) ?i.id: i,
    };
  }

  /// Writes pending answers, then checks the form for saving; `true` when
  /// nothing blocks it.
  Future<bool> prepareSave() async {
    await autosave.flush();
    final blocking = fillKey.currentState?.validateForSave() ?? const [];
    return blocking.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.evaluation;
    final draft = e.status == EvaluationStatus.draft;
    return EvaluationPage(
      children: [
        EvaluationEditTopBar(
          evaluation: e,
          onBack: widget.onBack,
          pdfAction: widget.pdfAction,
        ),
        EvaluationHeadCard(
          title: EvaluationNames.person(ref, e.createdFor),
          subtitle: widget.template.name,
          status: e.status,
        ),
        EvaluationPeriodCard(evaluation: e),
        EvaluationFillBody(
          key: fillKey,
          layout: layout,
          initialAnswers: EvaluationAnswerAdapter.toValues(e.answers),
          readOnly: !draft,
          validateOnOpen: draft && e.answers.isNotEmpty,
          onAnswerChanged: autosave.schedule,
          onAnswerFocusChanged: autosave.focusChanged,
          evidenceBuilder: (itemId) => EvaluationEvidenceSlot(
            evaluationId: e.id,
            itemId: itemId,
            editable: draft,
            pdfAction: widget.pdfAction,
          ),
        ),
        EvaluationManagementCard(
          evaluation: e,
          prepareSave: prepareSave,
          onIncomplete: (ids) => fillKey.currentState?.markIncomplete(ids),
          onDeleted: widget.onDeleted,
          onTransferred: widget.onTransferred,
        ),
        EvaluationInfoCard(evaluation: e, templateName: widget.template.name),
      ],
    );
  }
}
