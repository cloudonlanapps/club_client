import 'dart:typed_data';

import 'package:cl_remote_store/cl_remote_store.dart'
    show ClEvaluationsMasterNotifier, clEvaluationsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show EvaluationStaffView, EvaluationStatus, EvaluationTemplate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart'
    show
        EvaluationAnswerValue,
        EvaluationFillBody,
        EvaluationFillBodyState,
        EvaluationItemValue,
        EvaluationLayoutEntry;

import '../constants/evaluation_view_sizes.dart';
import '../constants/evaluation_view_strings.dart';
import '../models/evaluation_answer_adapter.dart';
import '../models/evaluation_answer_submit.dart';
import '../models/evaluation_layout_adapter.dart';
import '../utils/evaluation_autosave.dart';
import '../utils/evaluation_error_toast.dart';
import '../utils/evaluation_names.dart';
import 'evaluation_clear_answer_prompt.dart';
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
    required this.onOpenPdfBytes,
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

  /// Shows a downloaded PDF as bytes: the member copy or evidence.
  final ValueChanged<Uint8List> onOpenPdfBytes;

  @override
  ConsumerState<EvaluationEditBody> createState() => EvaluationEditBodyState();
}

/// State of [EvaluationEditBody]: the fill form and the autosave.
class EvaluationEditBodyState extends ConsumerState<EvaluationEditBody> {
  /// The fill form.
  final GlobalKey<EvaluationFillBodyState> fillKey =
      GlobalKey<EvaluationFillBodyState>();

  /// The evaluations master, kept for writes that outlive the view.
  late final ClEvaluationsMasterNotifier notifier;

  /// Writes each answer once it settles.
  late final EvaluationAutosave autosave;

  /// The template's items and sections, as the fill form takes them.
  late List<EvaluationLayoutEntry> layout;

  /// The template's items by id.
  late Map<int, EvaluationItemValue> items;

  /// The evaluation as last read or written, for the next answer write.
  late EvaluationStaffView latest = widget.evaluation;

  @override
  void initState() {
    super.initState();
    notifier = ref.read(clEvaluationsMasterProvider.notifier);
    autosave = EvaluationAutosave(
      delay: EvaluationViewSizes.autosaveDelay,
      write: write,
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
    latest = widget.evaluation;
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
    items = {
      for (final i in EvaluationLayoutEntry.flatten(layout)) ?i.id: i,
    };
  }

  /// Writes [answer] to item [itemId] of the evaluation as it stands now;
  /// clearing an answer that has evidence is confirmed first.
  Future<void> write(int itemId, EvaluationAnswerValue answer) async {
    final item = items[itemId];
    if (item == null) return;
    final go = await confirmClearAnswer(
      mounted ? context : null,
      fill: fillKey.currentState,
      evaluation: latest,
      item: item,
      answer: answer,
    );
    if (!go) return;
    final written = await EvaluationAnswerSubmit.save(
      evaluation: latest,
      item: item,
      answer: answer,
      notifier: notifier,
    );
    if (written != null) latest = written;
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
          onOpenPdfBytes: widget.onOpenPdfBytes,
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
          evidenceBuilder: (itemId) => EvaluationEvidenceSlot(
            evaluationId: e.id,
            itemId: itemId,
            editable: draft,
            onOpenPdfBytes: widget.onOpenPdfBytes,
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
