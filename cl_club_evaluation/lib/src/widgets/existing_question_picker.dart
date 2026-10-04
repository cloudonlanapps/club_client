import 'package:cl_remote_store/cl_remote_store.dart'
    show EvaluationItemSearchQuery, clEvaluationItemSearchProvider;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show EvaluationItemKind, EvaluationItemValue;

import '../constants/evaluation_view_sizes.dart';
import '../constants/evaluation_view_strings.dart';
import '../models/evaluation_item_adapter.dart';
import 'existing_question_row.dart';

/// Searches the questions of every template by text and type, and reports
/// the one tapped as a copy ([EvaluationItemAdapter.copyOf]). Info texts
/// are never copies, so they are not offered.
class ExistingQuestionPicker extends ConsumerStatefulWidget {
  /// A picker reporting through [onPicked].
  const ExistingQuestionPicker({required this.onPicked, super.key});

  /// Called with the copy of the question tapped.
  final ValueChanged<EvaluationItemValue> onPicked;

  @override
  ConsumerState<ExistingQuestionPicker> createState() =>
      ExistingQuestionPickerState();
}

/// State of [ExistingQuestionPicker]: the query.
class ExistingQuestionPickerState
    extends ConsumerState<ExistingQuestionPicker> {
  /// What is being searched for.
  EvaluationItemSearchQuery query = const EvaluationItemSearchQuery();

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final hits = ref.watch(clEvaluationItemSearchProvider(query));
    final questions = [
      for (final hit
          in hits.valueOrNull ?? const <sdk.EvaluationTemplateItemHit>[])
        if (hit.item.type.isQuestion) hit,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: EvaluationViewSizes.smallGap,
      children: [
        ShadInput(
          placeholder: const Text(EvaluationViewStrings.searchQuestions),
          keyboardType: TextInputType.text,
          onChanged: (text) =>
              setState(() => query = query.copyWith(search: () => text)),
        ),
        ShadSelect<EvaluationItemKind?>(
          placeholder: const Text(EvaluationViewStrings.anyType),
          minWidth: double.infinity,
          options: [
            const ShadOption(
              value: null,
              child: Text(EvaluationViewStrings.anyType),
            ),
            for (final kind in EvaluationItemKind.values)
              if (kind.isQuestion)
                ShadOption(value: kind, child: Text(kind.label)),
          ],
          selectedOptionBuilder: (context, kind) =>
              Text(kind?.label ?? EvaluationViewStrings.anyType),
          onChanged: (kind) => setState(
            () => query = query.copyWith(
              type: () =>
                  kind == null ? null : EvaluationItemAdapter.typeOf(kind),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: EvaluationViewSizes.resultsHeight,
          ),
          child: hits.isLoading
              ? const Center(child: ShadProgress())
              : questions.isEmpty
              ? Text(
                  EvaluationViewStrings.noQuestionsFound,
                  style: theme.textTheme.muted,
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final hit in questions)
                      ExistingQuestionRow(
                        hit: hit,
                        onTap: () => widget.onPicked(
                          EvaluationItemAdapter.copyOf(hit.item),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
