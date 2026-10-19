import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../constants/evaluation_strings.dart';
import '../../../models/evaluation_item_value.dart';
import '../../../models/evaluation_layout_entry.dart';
import '../fill/evaluation_fill_body.dart';
import 'evaluation_evidence_placeholder.dart';

/// A template's [layout] as the review form a coach writes on, in view mode
/// (club_client#28; pure UI: no SDK, no Riverpod). It is the fill form,
/// read-only and with no answers: each question shows its input empty and
/// disabled, its comment area where it has one and a placeholder where it
/// allows evidence; private items are greyed and the closing Q & As come
/// last.
///
/// The layout may hold items not yet created (no id): the preview gives
/// them ids of its own, below zero, which go nowhere. It follows each new
/// [layout] from scratch, so a changed item never shows a stale input.
class EvaluationTemplatePreview extends StatelessWidget {
  /// Previews [layout].
  const EvaluationTemplatePreview({required this.layout, super.key});

  /// The template's items and sections, as they stand.
  final List<EvaluationLayoutEntry> layout;

  /// [layout] with every item carrying an id: its own, or one below zero.
  static List<EvaluationLayoutEntry> withIds(
    List<EvaluationLayoutEntry> layout,
  ) {
    var next = 0;
    EvaluationItemValue identified(EvaluationItemValue item) =>
        item.id == null ? item.copyWith(id: () => --next) : item;
    return [
      for (final entry in layout)
        if (entry.isSection)
          entry.copyWith(sectionItems: [...entry.sectionItems.map(identified)])
        else
          entry.copyWith(item: () => identified(entry.item!)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final items = EvaluationLayoutEntry.flatten(layout);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: EvaluationSpacing.elementGap,
      children: [
        Text(EvaluationStrings.previewIntro, style: theme.textTheme.muted),
        if (items.isEmpty)
          Text(EvaluationStrings.previewEmpty, style: theme.textTheme.muted)
        else
          EvaluationFillBody(
            key: ValueKey(Object.hashAll(layout)),
            layout: withIds(layout),
            initialAnswers: const {},
            onAnswerChanged: (_, _) {},
            evidenceBuilder: (_) => const EvaluationEvidencePlaceholder(),
            readOnly: true,
          ),
      ],
    );
  }
}
